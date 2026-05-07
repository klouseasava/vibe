import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SyncDatabase {
  static final SyncDatabase instance = SyncDatabase._init();
  static Database? _database;

  SyncDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vibe_sync.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_educate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sign_name TEXT,
        country TEXT,
        landmarks_json TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<void> queueSign(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('pending_educate', data);
  }

  Future<List<Map<String, dynamic>>> getPendingSigns() async {
    final db = await instance.database;
    return await db.query('pending_educate');
  }

  Future<void> deleteSign(int id) async {
    final db = await instance.database;
    await db.delete('pending_educate', where: 'id = ?', whereArgs: [id]);
  }
}
