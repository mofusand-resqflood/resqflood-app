import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood_app/models/offline_item.dart';
import 'package:resqflood_app/services/connectivity_service.dart';
import 'package:resqflood_app/services/offline_queue_service.dart';
import 'package:resqflood_app/services/sync_service.dart';

class FakeConnectivityService implements ConnectivityService {
  bool connected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  FakeConnectivityService({this.connected = false});

  void setConnected(bool value) {
    connected = value;
    _controller.add(value);
  }

  @override
  Future<bool> checkConnection() async => connected;

  @override
  Stream<bool> get connectionStream async* {
    yield connected;
    yield* _controller.stream.distinct();
  }

  Future<void> dispose() async => _controller.close();
}

class InMemoryOfflineQueueService implements OfflineQueueService {
  final List<OfflineItem> _items = [];
  int _nextId = 1;

  final StreamController<int> _countController =
  StreamController<int>.broadcast();
  final StreamController<List<OfflineItem>> _itemsController =
  StreamController<List<OfflineItem>>.broadcast();

  @override
  QueueItemAddedCallback? onItemQueued;

  @override
  Stream<int> get queueCountStream => _countController.stream;

  @override
  Stream<List<OfflineItem>> get itemsStream => _itemsController.stream;

  @override
  Future<int> addToQueue({
    required String requestType,
    required String payload,
    String? clientId,
    DateTime? createdAt,
  }) async {
    final resolvedClientId = clientId ?? 'fixed-uuid-$_nextId';
    if (_items.any((e) => e.clientId == resolvedClientId)) {
      return 0;
    }

    final id = _nextId++;
    _items.add(
      OfflineItem(
        id: id,
        clientId: resolvedClientId,
        requestType: requestType,
        payload: payload,
        status: OfflineItemStatus.pending,
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
    await refreshQueueCount();
    if (onItemQueued != null) {
      await onItemQueued!();
    }
    return id;
  }

  @override
  Future<int> getQueuedCount() async => _items
      .where(
        (e) =>
    e.status == OfflineItemStatus.pending ||
        e.status == OfflineItemStatus.failed,
  )
      .length;

  @override
  Future<List<OfflineItem>> getPendingItemsInOrder() async {
    final pending = _items
        .where(
          (e) =>
      e.status == OfflineItemStatus.pending ||
          e.status == OfflineItemStatus.failed,
    )
        .toList()
      ..sort((a, b) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        return cmp != 0 ? cmp : (a.id ?? 0).compareTo(b.id ?? 0);
      });
    return pending;
  }

  @override
  Future<List<OfflineItem>> getAllItems() async => List.unmodifiable(_items);

  @override
  Future<void> markSyncing(int id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(status: OfflineItemStatus.syncing);
    }
  }

  @override
  Future<void> markSynced(int id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(
        status: OfflineItemStatus.synced,
        clearNextRetryAt: true,
        clearLastError: true,
      );
      await refreshQueueCount();
    }
  }

  @override
  Future<void> markFailed({
    required int id,
    required int retryCount,
    required DateTime nextRetryAt,
    required String errorMessage,
  }) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(
        status: OfflineItemStatus.failed,
        retryCount: retryCount,
        nextRetryAt: nextRetryAt,
        lastError: errorMessage,
      );
      await refreshQueueCount();
    }
  }

  @override
  Future<void> recoverStuckItems() async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].status == OfflineItemStatus.syncing) {
        _items[i] = _items[i].copyWith(status: OfflineItemStatus.pending);
      }
    }
  }

  @override
  Future<void> refreshQueueCount() async {
    if (!_countController.isClosed) {
      _countController.add(await getQueuedCount());
    }
    if (!_itemsController.isClosed) {
      _itemsController.add(await getAllItems());
    }
  }

  @override
  Future<void> dispose() async {
    await _countController.close();
    await _itemsController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RQF-329 Offline Queue & Automatic Sync', () {
    test('sends queued items strictly in chronological (FIFO) order once only',
            () async {
          final connectivity = FakeConnectivityService(connected: false);
          final queue = InMemoryOfflineQueueService();
          final sentClientIds = <String>[];

          final syncService = SyncService.forTesting(
            connectivityService: connectivity,
            queueService: queue,
            itemHandler: (item) async {
              sentClientIds.add(item.clientId);
            },
          );

          final t1 = DateTime(2026, 11, 28, 8, 0, 0);
          final t2 = DateTime(2026, 11, 28, 8, 1, 0);

          // Queue second item first with an earlier timestamp to verify time ordering
          await queue.addToQueue(
            requestType: 'sos',
            payload: '{"description":"Second submitted"}',
            clientId: 'uuid-second',
            createdAt: t2,
          );
          await queue.addToQueue(
            requestType: 'sos',
            payload: '{"description":"First submitted"}',
            clientId: 'uuid-first',
            createdAt: t1,
          );

          await syncService.start();
          expect(sentClientIds, isEmpty);

          // Restore connection -> triggers automatic sync
          connectivity.setConnected(true);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(sentClientIds, ['uuid-first', 'uuid-second']);
          expect(await queue.getQueuedCount(), 0);

          // Subsequent sync pass does not resend already-synced items
          await syncService.syncPendingItems();
          expect(sentClientIds, ['uuid-first', 'uuid-second']);

          await syncService.dispose();
          await queue.dispose();
          await connectivity.dispose();
        });

    test('retries failed items with delay and reuses fixed client ID', () async {
      final connectivity = FakeConnectivityService(connected: true);
      final queue = InMemoryOfflineQueueService();
      final attemptedIds = <String>[];
      var shouldFail = true;

      final syncService = SyncService.forTesting(
        connectivityService: connectivity,
        queueService: queue,
        itemHandler: (item) async {
          attemptedIds.add(item.clientId);
          if (shouldFail) {
            throw Exception('Simulated network timeout');
          }
        },
      );

      await queue.addToQueue(
        requestType: 'sos',
        payload: '{"description":"Retry test"}',
        clientId: 'fixed-id-123',
      );

      // First attempt fails and schedules a future nextRetryAt
      await syncService.syncPendingItems();
      expect(attemptedIds, ['fixed-id-123']);

      final itemsAfterFail = await queue.getAllItems();
      expect(itemsAfterFail.first.status, OfflineItemStatus.failed);
      expect(itemsAfterFail.first.retryCount, 1);
      expect(itemsAfterFail.first.nextRetryAt, isNotNull);

      // Calling sync before nextRetryAt passes must NOT retry yet
      await syncService.syncPendingItems();
      expect(attemptedIds, ['fixed-id-123']);

      // Once retry delay has elapsed, the same fixed clientId is retried and succeeds
      shouldFail = false;
      final futureTime = DateTime.now().add(const Duration(seconds: 10));
      await syncService.syncPendingItems(nowOverride: futureTime);

      expect(attemptedIds, ['fixed-id-123', 'fixed-id-123']);
      expect(await queue.getQueuedCount(), 0);

      await syncService.dispose();
      await queue.dispose();
      await connectivity.dispose();
    });

    test('computeRetryDelay applies exponential backoff capped at 30s', () {
      expect(SyncService.computeRetryDelay(1), const Duration(seconds: 2));
      expect(SyncService.computeRetryDelay(2), const Duration(seconds: 4));
      expect(SyncService.computeRetryDelay(3), const Duration(seconds: 8));
      expect(SyncService.computeRetryDelay(4), const Duration(seconds: 16));
      expect(SyncService.computeRetryDelay(5), const Duration(seconds: 30));
      expect(SyncService.computeRetryDelay(10), const Duration(seconds: 30));
    });
  });
}
