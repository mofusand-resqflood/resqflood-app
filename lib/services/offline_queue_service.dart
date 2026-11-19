
import 'dart:async';

import 'local_database.dart';

class OfflineQueueService {
  OfflineQueueService._();

  static final OfflineQueueService instance = OfflineQueueService._();

  final LocalDatabase _database = LocalDatabase.instance;

  final StreamController<int> _queueCountController =
  StreamController<int>.broadcast();

  Stream<int> get queueCountStream => _queueCountController.stream;

  Future<int> getQueuedCount() async {
    return await _database.getQueuedCount();
  }

  Future<void> refreshQueueCount() async {
    final count = await getQueuedCount();

    if (!_queueCountController.isClosed) {
      _queueCountController.add(count);
    }
  }

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

  Future<void> dispose() async {
    await _queueCountController.close();
  }
}
