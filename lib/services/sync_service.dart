import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/offline_item.dart';
import 'connectivity_service.dart';
import 'offline_queue_service.dart';

typedef SyncItemHandler = Future<void> Function(OfflineItem item);

class SyncService with WidgetsBindingObserver {
  SyncService._({
    ConnectivityService? connectivityService,
    OfflineQueueService? queueService,
    SyncItemHandler? itemHandler,
  })  : _connectivityService = connectivityService ?? ConnectivityService(),
        _queueService = queueService ?? OfflineQueueService.instance {
    _itemHandler = itemHandler ?? _defaultSyncItemHandler;
  }

  static final SyncService instance = SyncService._();

  /// Factory constructor for isolated unit/widget tests.
  factory SyncService.forTesting({
    required ConnectivityService connectivityService,
    required OfflineQueueService queueService,
    required SyncItemHandler itemHandler,
  }) {
    return SyncService._(
      connectivityService: connectivityService,
      queueService: queueService,
      itemHandler: itemHandler,
    );
  }

  final ConnectivityService _connectivityService;
  final OfflineQueueService _queueService;
  late final SyncItemHandler _itemHandler;

  StreamSubscription<bool>? _connectionSub;
  Timer? _retryTimer;
  bool _isStarted = false;
  bool _isSyncing = false;
  bool _isOnline = false;

  final StreamController<bool> _syncingStateController =
  StreamController<bool>.broadcast();

  Stream<bool> get isSyncingStream => _syncingStateController.stream;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;

  /// Computes exponential retry delay: 2s, 4s, 8s, 16s, max 30s.
  static Duration computeRetryDelay(int retryCount) {
    final exponent = retryCount.clamp(1, 5) - 1;
    final seconds = (2 * (1 << exponent)).clamp(2, 30);
    return Duration(seconds: seconds);
  }

  /// Starts listening to connectivity changes and triggers initial queue sync.
  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    WidgetsBinding.instance.addObserver(this);
    await _queueService.recoverStuckItems();

    _queueService.onItemQueued = () async {
      if (await _connectivityService.checkConnection()) {
        await syncPendingItems();
      }
    };

    _connectionSub = _connectivityService.connectionStream.listen(
          (connected) {
        _isOnline = connected;
        if (connected) {
          _retryTimer?.cancel();
          unawaited(syncPendingItems());
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncPendingItems());
    }
  }

  /// Syncs all ready queued items in strict chronological (FIFO) order.
  Future<void> syncPendingItems({DateTime? nowOverride}) async {
    if (_isSyncing) return;

    final connected = await _connectivityService.checkConnection();
    _isOnline = connected;
    if (!connected) return;

    _isSyncing = true;
    _emitSyncing(true);

    try {
      final items = await _queueService.getPendingItemsInOrder();
      final now = nowOverride ?? DateTime.now();

      for (final item in items) {
        if (item.id == null) continue;

        if (!item.isReadyToSync(now)) {
          _scheduleRetryTimer(item.nextRetryAt!);
          // Stop here to preserve strict FIFO ordering across queued items.
          break;
        }

        // Re-check connectivity before sending each item.
        if (!await _connectivityService.checkConnection()) {
          _isOnline = false;
          break;
        }

        await _queueService.markSyncing(item.id!);

        try {
          await _itemHandler(item);
          await _queueService.markSynced(item.id!);
        } catch (error) {
          final nextAttempt = item.retryCount + 1;
          final delay = computeRetryDelay(nextAttempt);
          final nextRetryAt = DateTime.now().add(delay);

          await _queueService.markFailed(
            id: item.id!,
            retryCount: nextAttempt,
            nextRetryAt: nextRetryAt,
            errorMessage: error.toString(),
          );

          _scheduleRetryTimer(nextRetryAt);
          // Stop processing subsequent items so FIFO order is strictly preserved.
          break;
        }
      }
    } finally {
      _isSyncing = false;
      _emitSyncing(false);
    }
  }

  void _scheduleRetryTimer(DateTime nextRetryAt) {
    _retryTimer?.cancel();
    final delay = nextRetryAt.difference(DateTime.now());
    final effectiveDelay =
    delay.isNegative ? const Duration(milliseconds: 50) : delay;

    _retryTimer = Timer(effectiveDelay, () {
      unawaited(syncPendingItems());
    });
  }

  void _emitSyncing(bool value) {
    if (!_syncingStateController.isClosed) {
      _syncingStateController.add(value);
    }
  }

  /// Default dispatcher sending queued items to Supabase with fixed-ID deduplication.
  Future<void> _defaultSyncItemHandler(OfflineItem item) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw StateError('Cannot sync offline item while signed out.');
    }

    final data = item.decodedPayload;
    final refTag = '[ref:${item.clientId}]';

    switch (item.requestType) {
      case 'sos':
      // Deduplication guard: if a previous attempt succeeded on the server
      // before the client lost connection, do not insert a duplicate row.
        final existing = await client
            .from('requests')
            .select('id')
            .eq('resident_id', user.id)
            .ilike('description', '%$refTag%')
            .maybeSingle();

        if (existing != null) {
          return;
        }

        final rawDescription = (data['description'] as String? ?? '').trim();
        final location = (data['location'] as String? ?? '').trim();
        final medicalEmergency = data['medical_emergency'] == true;
        final emergencyType =
        (data['emergency_type'] as String? ?? 'Evacuation').trim();
        final peopleCount = (data['people_affected'] as num?)?.toInt() ?? 1;

        final combinedDescription = [
          if (rawDescription.isNotEmpty) rawDescription,
          if (location.isNotEmpty) 'Location: $location',
          refTag,
        ].join('\n');

        await client.from('requests').insert({
          'resident_id': user.id,
          'description': combinedDescription,
          'help_type': emergencyType,
          'people_count': peopleCount < 1 ? 1 : peopleCount,
          'victim_categories': medicalEmergency ? ['medical'] : <String>[],
          if (data['latitude'] is num)
            'latitude': (data['latitude'] as num).toDouble(),
          if (data['longitude'] is num)
            'longitude': (data['longitude'] as num).toDouble(),
        });
        break;

      case 'blocked_road':
        final existingRoad = await client
            .from('blocked_roads')
            .select('id')
            .eq('reporter_id', user.id)
            .ilike('note', '%$refTag%')
            .maybeSingle();

        if (existingRoad != null) {
          return;
        }

        final roadName = (data['road_name'] as String? ?? 'Reported Road').trim();
        final rawNote = (data['note'] as String? ?? '').trim();
        final noteWithRef =
        rawNote.isEmpty ? refTag : '$rawNote\n$refTag';

        await client.from('blocked_roads').insert({
          'reporter_id': user.id,
          'road_name': roadName,
          'note': noteWithRef,
          'latitude': (data['latitude'] as num?)?.toDouble() ?? 0.0,
          'longitude': (data['longitude'] as num?)?.toDouble() ?? 0.0,
          if (data['photo_path'] is String) 'photo_path': data['photo_path'],
        });
        break;

      default:
        throw UnsupportedError(
          'Unsupported offline request type: ${item.requestType}',
        );
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectionSub?.cancel();
    _retryTimer?.cancel();
    await _syncingStateController.close();
    _isStarted = false;
  }
}
