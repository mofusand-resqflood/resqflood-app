import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    final db = await database;

    return await db.insert('offline_queue', {
      'request_type': requestType,
      'payload': payload,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
