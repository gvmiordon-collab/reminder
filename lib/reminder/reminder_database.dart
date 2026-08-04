import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'reminder_model.dart';

class ReminderDatabase {
  ReminderDatabase._internal();
  static final ReminderDatabase instance = ReminderDatabase._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'reminders.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            dueDate INTEGER NOT NULL,
            hasTime INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<Reminder> insertReminder(Reminder reminder) async {
    final db = await _database;
    final map = reminder.toMap()..remove('id');
    final id = await db.insert('reminders', map);
    return Reminder(
      id: id,
      title: reminder.title,
      dueDate: reminder.dueDate,
      hasTime: reminder.hasTime,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
    );
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await _database;
    final maps = await db.query('reminders', orderBy: 'dueDate ASC');
    return maps.map(Reminder.fromMap).toList();
  }

  Future<void> deleteReminder(int id) async {
    final db = await _database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}