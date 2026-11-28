import 'dart:async';

import '../models/offline_item.dart';
import 'local_database.dart';

typedef QueueItemAddedCallback = Future<void> Function();

class OfflineQueueService {
  OfflineQueueService._();

  static final OfflineQueueService instance = OfflineQueueService._();

  final LocalDatabase _database = LocalDatabase.instance;

  final StreamController<int> _queueCountController =
  StreamController<int>.broadcast();

  final StreamController<List<OfflineItem>> _itemsController =
  StreamController<List<OfflineItem>>.broadcast();

  /// Optional hook registered by SyncService to flush immediately when online.
  QueueItemAddedCallback? onItemQueued;

  Stream<int> get queueCountStream => _queueCountController.stream;

  Stream<List<OfflineItem>> get itemsStream => _itemsController.stream;

  Future<int> getQueuedCount() async {
    return await _database.getQueuedCount();
  }

  Future<List<OfflineItem>> getPendingItemsInOrder() async {
    return await _database.getPendingItemsInOrder();
  }

  Future<List<OfflineItem>> getAllItems() async {
    return await _database.getAllItems();
  }

  Future<void> refreshQueueCount() async {
    final count = await getQueuedCount();
    if (!_queueCountController.isClosed) {
      _queueCountController.add(count);
    }

    if (!_itemsController.isClosed) {
      final items = await getAllItems();
      _itemsController.add(items);
    }
  }

  Future<int> addToQueue({
    required String requestType,
    required String payload,
    String? clientId,
    DateTime? createdAt,
  }) async {
    final id = await _database.addToQueue(
      requestType: requestType,
      payload: payload,
      clientId: clientId,
      createdAt: createdAt,
    );

    await refreshQueueCount();

    if (onItemQueued != null) {
      unawaited(onItemQueued!());
    }

    return id;
  }

  Future<void> recoverStuckItems() async {
    await _database.recoverStuckSyncingItems();
    await refreshQueueCount();
  }

  Future<void> markSyncing(int id) async {
    await _database.markSyncing(id);
    await refreshQueueCount();
  }

  Future<void> markSynced(int id) async {
    await _database.markSynced(id);
    await refreshQueueCount();
  }

  Future<void> markFailed({
    required int id,
    required int retryCount,
    required DateTime nextRetryAt,
    required String errorMessage,
  }) async {
    await _database.markFailed(
      id: id,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      errorMessage: errorMessage,
    );
    await refreshQueueCount();
  }

  Future<void> dispose() async {
    await _queueCountController.close();
    await _itemsController.close();
  }
}
