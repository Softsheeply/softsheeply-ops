import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shiftrest.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        name TEXT,
        job_type TEXT,
        sleep_goal_hours REAL DEFAULT 7.5,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        shift_type TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sleep_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        sleep_start TEXT,
        sleep_end TEXT,
        quality INTEGER,
        notes TEXT,
        is_split_sleep INTEGER DEFAULT 0,
        split_sleep_start2 TEXT,
        split_sleep_end2 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sleep_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        for_date TEXT NOT NULL,
        window_start TEXT,
        window_end TEXT,
        duration_hours REAL,
        plan_type TEXT,
        is_completed INTEGER DEFAULT 0,
        caffeine_deadline TEXT,
        light_guidance TEXT,
        notes TEXT
      )
    ''');
  }

  // ---- Profile ----

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final result = await db.query('profile', where: 'id = 1');
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final db = await database;
    final existing = await getProfile();
    if (existing == null) {
      await db.insert('profile', {'id': 1, ...data});
    } else {
      await db.update('profile', data, where: 'id = 1');
    }
  }

  // ---- Shifts ----

  Future<List<Map<String, dynamic>>> getShiftsForRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.query(
      'shifts',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  Future<Map<String, dynamic>?> getShiftForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'shifts',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertShift(Map<String, dynamic> shift) async {
    final db = await database;
    return await db.insert('shifts', shift,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateShift(int id, Map<String, dynamic> shift) async {
    final db = await database;
    return await db.update('shifts', shift, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteShift(int id) async {
    final db = await database;
    return await db.delete('shifts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUpcomingShifts(int days) async {
    final db = await database;
    final now = DateTime.now();
    final start = _formatDate(now);
    final end = _formatDate(now.add(Duration(days: days)));
    return await db.query(
      'shifts',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date ASC',
    );
  }

  // ---- Sleep Logs ----

  Future<int> insertSleepLog(Map<String, dynamic> log) async {
    final db = await database;
    return await db.insert('sleep_logs', log);
  }

  Future<int> updateSleepLog(int id, Map<String, dynamic> log) async {
    final db = await database;
    return await db.update('sleep_logs', log,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSleepLog(int id) async {
    final db = await database;
    return await db.delete('sleep_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSleepLogsForRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.query(
      'sleep_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentSleepLogs(int count) async {
    final db = await database;
    return await db.query(
      'sleep_logs',
      orderBy: 'date DESC',
      limit: count,
    );
  }

  // ---- Sleep Plans ----

  Future<void> upsertSleepPlan(Map<String, dynamic> plan) async {
    final db = await database;
    final existing = await db.query(
      'sleep_plans',
      where: 'for_date = ? AND plan_type = ?',
      whereArgs: [plan['for_date'], plan['plan_type']],
    );
    if (existing.isEmpty) {
      await db.insert('sleep_plans', plan);
    } else {
      await db.update(
        'sleep_plans',
        plan,
        where: 'for_date = ? AND plan_type = ?',
        whereArgs: [plan['for_date'], plan['plan_type']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSleepPlansForDate(String date) async {
    final db = await database;
    return await db.query(
      'sleep_plans',
      where: 'for_date = ?',
      whereArgs: [date],
      orderBy: 'window_start ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getSleepPlansForRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.query(
      'sleep_plans',
      where: 'for_date >= ? AND for_date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'for_date ASC, window_start ASC',
    );
  }

  Future<void> markSleepPlanCompleted(int id) async {
    final db = await database;
    await db.update(
      'sleep_plans',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---- Utilities ----

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('profile');
    await db.delete('shifts');
    await db.delete('sleep_logs');
    await db.delete('sleep_plans');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
