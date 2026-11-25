import 'dart:async';

import '../models/offline_item.dart';
import 'local_database.dart';

class OfflineQueueService {
  OfflineQueueService._();

  static final OfflineQueueService instance = OfflineQueueService._();

  final LocalDatabase _database = LocalDatabase.instance;

  StreamController<int> _queueCountController =
  StreamController<int>.broadcast();

  Stream<int> get queueCountStream => _queueCountController.stream;

  Future<int> getQueuedCount() async {
    return await _database.getQueuedCount();
  }

  Future<void> refreshQueueCount() async {
    final count = await getQueuedCount();

    if (_queueCountController.isClosed) {
      _queueCountController = StreamController<int>.broadcast();
    }
    _queueCountController.add(count);
  }

  /// Legacy string-based helper kept for backward compatibility
  Future<int> addToQueue({
    required String requestType,
    required String payload,
  }) async {
    final id = await _database.addToQueue(
      requestType: requestType,
      payload: payload,
    );

    await refreshQueueCount();
    return id;
  }

  /// Add a structured OfflineItem ('sos', 'update', or 'road_report')
  Future<OfflineItem> add({
    required OfflineItemType type,
    required Map<String, dynamic> payload,
    DateTime? createdAt,
  }) async {
    final item = OfflineItem(
      type: type,
      payload: payload,
      status: 'pending',
      createdAt: createdAt ?? DateTime.now(),
    );

    final saved = await _database.insertOfflineItem(item);
    await refreshQueueCount();
    return saved;
  }

  Future<OfflineItem> queueSos(Map<String, dynamic> payload) {
    return add(type: OfflineItemType.sos, payload: payload);
  }

  Future<OfflineItem> queueQuickUpdate(Map<String, dynamic> payload) {
    return add(type: OfflineItemType.update, payload: payload);
  }

  Future<OfflineItem> queueRoadReport(Map<String, dynamic> payload) {
    return add(type: OfflineItemType.roadReport, payload: payload);
  }

  /// List queued offline items (optionally filtered by type or status)
  Future<List<OfflineItem>> list({
    OfflineItemType? type,
    String? status = 'pending',
  }) async {
    return await _database.getOfflineItems(type: type, status: status);
  }

  /// Remove a synced/cancelled item from the local queue by ID
  Future<bool> remove(int id) async {
    final deletedRows = await _database.deleteOfflineItem(id);
    await refreshQueueCount();
    return deletedRows > 0;
  }

  Future<void> dispose() async {
    await _queueCountController.close();
  }
}
