import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static Database? _database;

  static const String _webQueuePrefix = 'rqf307.offline_queue.item.';
  static const String _webNextIdKey = 'rqf307.offline_queue.next_id';

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite database is unavailable on web. '
        'Use the LocalDatabase queue methods instead.',
      );
    }

    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'resqflood.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            request_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> getQueuedCount() async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();

      return preferences.getKeys().where((key) {
        if (!key.startsWith(_webQueuePrefix)) return false;

        final raw = preferences.getString(key);
        if (raw == null) return false;

        try {
          final item = jsonDecode(raw) as Map<String, dynamic>;
          return item['status'] == 'pending';
        } catch (_) {
          return false;
        }
      }).length;
    }

    final db = await database;

    final result = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM offline_queue "
      "WHERE status = ?",
      ['pending'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> addToQueue({
    required String requestType,
    required String payload,
  }) async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      final id = preferences.getInt(_webNextIdKey) ?? 1;

      await preferences.setInt(_webNextIdKey, id + 1);

      await preferences.setString(
        '$_webQueuePrefix$id',
        jsonEncode({
          'id': id,
          'request_type': requestType,
          'payload': payload,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      return id;
    }

    final db = await database;

    return db.insert('offline_queue', {
      'request_type': requestType,
      'payload': payload,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
