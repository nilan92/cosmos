import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Single thin wrapper over sqflite. Raw SQL, no ORM — ponytail: an ORM here
/// would be more code than the queries it replaces.
class DB {
  static Database? _db;

  static Future<Database> get _conn async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'cosmos.db');
    return openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute(
          'CREATE TABLE profile(id INTEGER PRIMARY KEY, name TEXT, created_at TEXT)');
      await d.execute('CREATE TABLE tasks('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, '
          'done INTEGER DEFAULT 0, priority INTEGER DEFAULT 1, created_at TEXT)');
      await d.execute('CREATE TABLE gratitude('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, day TEXT)');
      await d.execute('CREATE TABLE sessions('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, minutes INTEGER, completed_at TEXT)');
    });
  }

  static String get _today => DateTime.now().toIso8601String().substring(0, 10);

  // --- profile (lightweight local "login", no real auth) ---
  static Future<String?> profileName() async {
    final r = await (await _conn).query('profile', limit: 1);
    return r.isEmpty ? null : r.first['name'] as String;
  }

  static Future<void> setProfile(String name) async {
    final d = await _conn;
    await d.delete('profile');
    await d.insert('profile',
        {'id': 1, 'name': name, 'created_at': DateTime.now().toIso8601String()});
  }

  static Future<void> signOut() async => (await _conn).delete('profile');

  // --- tasks ---
  static Future<List<Map<String, Object?>>> tasks() async => (await _conn).query(
      'tasks',
      orderBy: 'done ASC, priority DESC, id DESC');

  static Future<void> addTask(String title, int priority) async =>
      (await _conn).insert('tasks', {
        'title': title,
        'priority': priority,
        'done': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

  static Future<void> toggleTask(int id, bool done) async => (await _conn)
      .update('tasks', {'done': done ? 1 : 0}, where: 'id=?', whereArgs: [id]);

  static Future<void> deleteTask(int id) async =>
      (await _conn).delete('tasks', where: 'id=?', whereArgs: [id]);

  // --- gratitude ---
  static Future<List<Map<String, Object?>>> gratitude() async =>
      (await _conn).query('gratitude', orderBy: 'day DESC, id DESC');

  static Future<int> gratitudeTodayCount() async {
    final r = await (await _conn).rawQuery(
        'SELECT COUNT(*) c FROM gratitude WHERE day=?', [_today]);
    return r.first['c'] as int;
  }

  static Future<void> addGratitude(String text) async => (await _conn)
      .insert('gratitude', {'text': text, 'day': _today});

  static Future<void> deleteGratitude(int id) async =>
      (await _conn).delete('gratitude', where: 'id=?', whereArgs: [id]);

  // --- focus sessions ---
  static Future<void> logSession(int minutes) async => (await _conn).insert(
      'sessions',
      {'minutes': minutes, 'completed_at': DateTime.now().toIso8601String()});

  /// Returns (sessionCount, totalMinutes) for today.
  static Future<(int, int)> focusToday() async {
    final r = await (await _conn).rawQuery(
        'SELECT COUNT(*) c, COALESCE(SUM(minutes),0) m FROM sessions '
        'WHERE substr(completed_at,1,10)=?',
        [_today]);
    return (r.first['c'] as int, r.first['m'] as int);
  }

  static Future<(int, int)> taskCounts() async {
    final r = await (await _conn).rawQuery(
        'SELECT COUNT(*) total, COALESCE(SUM(done),0) done FROM tasks');
    return (r.first['done'] as int, r.first['total'] as int);
  }

  /// Consecutive days (ending today) with any activity: gratitude, a completed
  /// focus session, or a task created.
  static Future<int> streak() async {
    final rows = await (await _conn).rawQuery(
        'SELECT day FROM ('
        '  SELECT day FROM gratitude'
        '  UNION SELECT substr(completed_at,1,10) FROM sessions'
        '  UNION SELECT substr(created_at,1,10) FROM tasks'
        ') WHERE day IS NOT NULL GROUP BY day');
    final days = rows.map((r) => r['day'] as String).toSet();
    String fmt(DateTime t) => t.toIso8601String().substring(0, 10);
    var cur = DateTime.now();
    var n = 0;
    while (days.contains(fmt(cur))) {
      n++;
      cur = cur.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// day (yyyy-mm-dd) -> number of gratitude entries, for the heatmap.
  static Future<Map<String, int>> gratitudeHeatmap() async {
    final r = await (await _conn)
        .rawQuery('SELECT day, COUNT(*) c FROM gratitude GROUP BY day');
    return {for (final row in r) row['day'] as String: row['c'] as int};
  }

  // --- backup / restore (local JSON file; foundation for cloud sync) ---
  static Future<String> get _backupPath async =>
      p.join(await getDatabasesPath(), 'cosmos_backup.json');

  static const _tables = ['profile', 'tasks', 'gratitude', 'sessions'];

  static Future<String> exportJson() async {
    final d = await _conn;
    final data = {for (final t in _tables) t: await d.query(t)};
    final path = await _backupPath;
    await File(path).writeAsString(jsonEncode(data));
    return path;
  }

  static Future<bool> importJson() async {
    final f = File(await _backupPath);
    if (!await f.exists()) return false;
    final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final d = await _conn;
    await d.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
        for (final row in (data[t] as List? ?? [])) {
          await txn.insert(t, Map<String, Object?>.from(row as Map));
        }
      }
    });
    return true;
  }
}
