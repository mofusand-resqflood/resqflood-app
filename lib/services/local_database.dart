import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/offline_item.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const String tableOfflineQueue = 'offline_queue';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  @visibleForTesting
  Future<void> setTestDatabase(Database db) async {
    _database = db;
    await createTables(db);
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'resqflood.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await createTables(db);
      },
    );
  }

  Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableOfflineQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> getQueuedCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tableOfflineQueue WHERE status = ?',
      ['pending'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> addToQueue({
    required String requestType,
    required String payload,
  }) async {
    // Validate supported request types ('sos', 'update', 'road_report')
    OfflineItemType.fromString(requestType);

    final db = await database;
    return await db.insert(tableOfflineQueue, {
      'request_type': requestType,
      'payload': payload,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<OfflineItem> insertOfflineItem(OfflineItem item) async {
    final db = await database;
    final id = await db.insert(tableOfflineQueue, item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<OfflineItem>> getOfflineItems({
    OfflineItemType? type,
    String? status = 'pending',
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    if (type != null) {
      whereClauses.add('request_type = ?');
      whereArgs.add(type.value);
    }

    final rows = await db.query(
      tableOfflineQueue,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id ASC',
    );

    return rows.map(OfflineItem.fromMap).toList();
  }

  Future<int> deleteOfflineItem(int id) async {
    final db = await database;
    return await db.delete(
      tableOfflineQueue,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllOfflineItems() async {
    final db = await database;
    return await db.delete(tableOfflineQueue);
  }
}
