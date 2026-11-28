import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/offline_item.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'resqflood.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id TEXT NOT NULL UNIQUE,
            request_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            next_retry_at TEXT,
            last_error TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_offline_queue_status_created '
              'ON offline_queue (status, created_at ASC, id ASC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE offline_queue ADD COLUMN client_id TEXT',
          );
          await db.execute(
            'ALTER TABLE offline_queue ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE offline_queue ADD COLUMN next_retry_at TEXT',
          );
          await db.execute(
            'ALTER TABLE offline_queue ADD COLUMN last_error TEXT',
          );

          final existing = await db.query('offline_queue');
          for (final row in existing) {
            final rowId = row['id'] as int;
            await db.update(
              'offline_queue',
              {'client_id': generateFixedId()},
              where: 'id = ?',
              whereArgs: [rowId],
            );
          }

          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_offline_queue_client_id '
                'ON offline_queue (client_id)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_offline_queue_status_created '
                'ON offline_queue (status, created_at ASC, id ASC)',
          );
        }
      },
    );
  }

  /// Generates a fixed RFC-4122 v4 UUID used as an idempotency key across retries.
  static String generateFixedId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  /// Counts items still waiting to sync (pending or failed).
  Future<int> getQueuedCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM offline_queue '
          'WHERE status IN (?, ?)',
      [OfflineItemStatus.pending.name, OfflineItemStatus.failed.name],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Inserts a new item with a fixed client_id so retries never create duplicates.
  Future<int> addToQueue({
    required String requestType,
    required String payload,
    String? clientId,
    DateTime? createdAt,
  }) async {
    final db = await database;
    final resolvedClientId = clientId ?? generateFixedId();

    return await db.insert(
      'offline_queue',
      {
        'client_id': resolvedClientId,
        'request_type': requestType,
        'payload': payload,
        'status': OfflineItemStatus.pending.name,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'retry_count': 0,
        'next_retry_at': null,
        'last_error': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Returns all unsynced items strictly ordered by creation time (FIFO).
  Future<List<OfflineItem>> getPendingItemsInOrder() async {
    final db = await database;
    final rows = await db.query(
      'offline_queue',
      where: 'status IN (?, ?)',
      whereArgs: [OfflineItemStatus.pending.name, OfflineItemStatus.failed.name],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(OfflineItem.fromMap).toList();
  }

  /// Returns all queue items ordered chronologically (useful for sync status UI).
  Future<List<OfflineItem>> getAllItems() async {
    final db = await database;
    final rows = await db.query(
      'offline_queue',
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(OfflineItem.fromMap).toList();
  }

  /// Resets any items left in 'syncing' if the app closed mid-request.
  Future<void> recoverStuckSyncingItems() async {
    final db = await database;
    await db.update(
      'offline_queue',
      {'status': OfflineItemStatus.pending.name},
      where: 'status = ?',
      whereArgs: [OfflineItemStatus.syncing.name],
    );
  }

  Future<void> markSyncing(int id) async {
    final db = await database;
    await db.update(
      'offline_queue',
      {'status': OfflineItemStatus.syncing.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      'offline_queue',
      {
        'status': OfflineItemStatus.synced.name,
        'next_retry_at': null,
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed({
    required int id,
    required int retryCount,
    required DateTime nextRetryAt,
    required String errorMessage,
  }) async {
    final db = await database;
    await db.update(
      'offline_queue',
      {
        'status': OfflineItemStatus.failed.name,
        'retry_count': retryCount,
        'next_retry_at': nextRetryAt.toIso8601String(),
        'last_error': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
