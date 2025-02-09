import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> init() async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'food_tracker.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE foods(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            weight INTEGER,
            kcal_per_hundred INTEGER,
            kcal_total INTEGER,
            UNIQUE(name, weight, kcal_per_hundred, kcal_total)
          )
        ''');

        await db.execute('''
          CREATE TABLE diary(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            weight INTEGER NOT NULL,
            FOREIGN KEY(food_id) REFERENCES foods(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE recent_foods(
            food_id INTEGER PRIMARY KEY,
            count INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY(food_id) REFERENCES foods(id)
          )
        ''');
      },
      version: 1,
    );
    return database;
  }
}
