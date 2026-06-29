import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ride.dart';
import '../models/goal.dart';
import '../models/expense.dart';
import '../models/shift.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meta_moto.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adiciona coluna dist_km na tabela rides
      await db.execute('ALTER TABLE rides ADD COLUMN dist_km REAL');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rides (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        plataforma TEXT NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,
        shift_id INTEGER,
        dist_km REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        data TEXT NOT NULL,
        km REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor_diario REAL NOT NULL DEFAULT 0,
        valor_semanal REAL NOT NULL DEFAULT 0,
        valor_mensal REAL NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inicio TEXT NOT NULL,
        fim TEXT,
        total_ganho REAL NOT NULL DEFAULT 0,
        total_corridas INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE maintenance_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        km_atual REAL NOT NULL,
        km_proxima REAL NOT NULL,
        descricao TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ---- RIDES ----
  Future<int> insertRide(Ride ride) async {
    final db = await database;
    final map = ride.toMap()..remove('id');
    return await db.insert('rides', map);
  }

  Future<int> updateRide(Ride ride) async {
    final db = await database;
    return await db.update('rides', ride.toMap(), where: 'id = ?', whereArgs: [ride.id]);
  }

  Future<int> deleteRide(int id) async {
    final db = await database;
    return await db.delete('rides', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Ride>> getAllRides() async {
    final db = await database;
    final maps = await db.query('rides', orderBy: 'data DESC');
    return maps.map((m) => Ride.fromMap(m)).toList();
  }

  Future<List<Ride>> getRidesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'rides',
      where: 'data >= ? AND data <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'data DESC',
    );
    return maps.map((m) => Ride.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyEarningsForMonth(DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return db.rawQuery(
      '''SELECT substr(data, 1, 10) as dia, SUM(valor) as total, COUNT(*) as corridas
         FROM rides WHERE data >= ? AND data <= ?
         GROUP BY dia ORDER BY dia ASC''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<Map<String, double>> getEarningsByPlatform(DateTime? from, DateTime? to) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (from != null && to != null) {
      where = 'WHERE data >= ? AND data <= ?';
      args = [from.toIso8601String(), to.toIso8601String()];
    }
    final result = await db.rawQuery(
      'SELECT plataforma, SUM(valor) as total FROM rides $where GROUP BY plataforma',
      args,
    );
    final Map<String, double> map = {};
    for (final row in result) {
      map[row['plataforma'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  // ---- EXPENSES ----
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final map = expense.toMap()..remove('id');
    return await db.insert('expenses', map);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'data DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'data >= ? AND data <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'data DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  // ---- GOALS ----
  Future<Goal?> getGoal() async {
    final db = await database;
    final maps = await db.query('goals', orderBy: 'id DESC', limit: 1);
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

  Future<void> saveGoal(Goal goal) async {
    final db = await database;
    final existing = await getGoal();
    if (existing == null) {
      await db.insert('goals', goal.toMap()..remove('id'));
    } else {
      await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [existing.id]);
    }
  }

  // ---- SHIFTS ----
  Future<int> insertShift(Shift shift) async {
    final db = await database;
    final map = shift.toMap()..remove('id');
    return await db.insert('shifts', map);
  }

  Future<int> updateShift(Shift shift) async {
    final db = await database;
    return await db.update('shifts', shift.toMap(), where: 'id = ?', whereArgs: [shift.id]);
  }

  Future<Shift?> getActiveShift() async {
    final db = await database;
    final maps = await db.query('shifts', where: 'fim IS NULL', limit: 1);
    if (maps.isEmpty) return null;
    return Shift.fromMap(maps.first);
  }

  Future<List<Shift>> getAllShifts() async {
    final db = await database;
    final maps = await db.query('shifts', orderBy: 'inicio DESC', limit: 30);
    return maps.map((m) => Shift.fromMap(m)).toList();
  }

  // ---- MAINTENANCE ALERTS ----
  Future<int> upsertMaintenanceAlert(MaintenanceAlert alert) async {
    final db = await database;
    final existing = await db.query('maintenance_alerts', where: 'tipo = ?', whereArgs: [alert.tipo]);
    if (existing.isEmpty) {
      return await db.insert('maintenance_alerts', alert.toMap()..remove('id'));
    } else {
      return await db.update('maintenance_alerts', alert.toMap(), where: 'tipo = ?', whereArgs: [alert.tipo]);
    }
  }

  Future<List<MaintenanceAlert>> getAllMaintenanceAlerts() async {
    final db = await database;
    final maps = await db.query('maintenance_alerts');
    return maps.map((m) => MaintenanceAlert.fromMap(m)).toList();
  }

  // ---- SETTINGS ----
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
