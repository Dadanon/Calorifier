import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class FoodProvider with ChangeNotifier {
  final Database database;
  final DiaryProvider diaryProvider;
  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  List<Food> _searchResults = [];
  List<Food> _recentFoods = [];

  FoodProvider(this.database, this.diaryProvider);

  List<Food> get searchResults => _searchResults;
  List<Food> get recentFoods => _recentFoods;
  List<Food> get filteredFoods => _filteredFoods;
  List<Food> get foods => _foods;

  Future<void> loadFoods() async {
    final List<Map<String, dynamic>> maps = await database.query('foods');
    _foods = maps.map((map) => Food.fromMap(map)).toList();
    _filteredFoods = foods;
    notifyListeners();
  }

  Future<void> filterFoods(String query) async {
    if (query.isEmpty) {
      _filteredFoods = foods;
      notifyListeners();
      return;
    }

    final results = await database.query(
      'foods',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    _filteredFoods = results.map((map) => Food.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> searchFoods(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final results = await database.query(
      'foods',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    _searchResults = results.map((map) => Food.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addFood(Food food) async {
    final existing = await database.query(
      'foods',
      where: 'LOWER(name) = LOWER(?)', // Регистронезависимая проверка
      whereArgs: [food.name],
    );

    if (existing.isNotEmpty) {
      throw Exception('Продукт с названием "${food.name}" уже существует');
    }

    await database.insert('foods', food.toMap());
    await loadFoods();
  }

  Future<void> updateFood(Food updatedFood) async {
    await database.update(
      'foods',
      updatedFood.toMap(),
      where: 'id = ?',
      whereArgs: [updatedFood.id],
    );
    await loadFoods();
  }

  Future<void> deleteFood(int foodId) async {
    await database.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [foodId],
    );
    await loadFoods();
  }

  Future<void> deleteRelatedRecentFoods(int foodId) async {
    await database
        .delete('recent_foods', where: 'food_id = ?', whereArgs: [foodId]);
    _recentFoods = _recentFoods.where((recent) => recent.id != foodId).toList();
  }

  Future<void> loadRecentFoods() async {
    final maps = await database.query(
      'recent_foods',
      orderBy: 'count DESC',
      limit: 10,
    );

    _recentFoods = await Future.wait(maps.map((map) async {
      final foodMap = await database.query(
        'foods',
        where: 'id = ?',
        whereArgs: [map['food_id']],
      );
      return Food.fromMap(foodMap.first);
    }));

    notifyListeners();
  }

  Future<void> incrementRecent(Food food) async {
    await database.insert(
      'recent_foods',
      {'food_id': food.id, 'count': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await database.rawUpdate(
      'UPDATE recent_foods SET count = count + 1 WHERE food_id = ?',
      [food.id],
    );
    await loadRecentFoods();
  }
}

class DiaryProvider with ChangeNotifier {
  final Database database;
  List<DiaryEntry> _entries = [];
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  DiaryProvider(this.database);

  List<DiaryEntry> get entries => _entries;
  int get totalKcal => _entries.fold(0, (sum, entry) => sum + entry.kcalTotal);

  Future<void> updateEntriesForFood(Food updatedFood) async {
    // Создаём новый список записей
    final newEntries = _entries.map((entry) {
      if (entry.food.id == updatedFood.id) {
        // Создаём новую запись с обновлённым продуктом
        return DiaryEntry(
            id: entry.id,
            food: updatedFood,
            date: entry.date,
            weight: entry.weight,
            type: entry.type);
      }
      return entry;
    }).toList();

    // Обновляем кэш и уведомляем слушателей
    _entries = newEntries;
    notifyListeners();
  }

  Future<void> loadEntries(DateTime date) async {
    _selectedDate = date;
    final formattedDate = _formatDate(date);

    final maps = await database.query(
      'diary',
      where: 'date = ?',
      whereArgs: [formattedDate],
    );

    _entries = await Future.wait(maps.map((map) async {
      final foodMap = await database.query(
        'foods',
        where: 'id = ?',
        whereArgs: [map['food_id']],
      );
      return DiaryEntry.fromMap(map, Food.fromMap(foodMap.first));
    }));

    notifyListeners();
  }

  Future<void> addEntry(
      Food food, DateTime date, int weight, String type) async {
    await database.insert('diary', {
      'food_id': food.id,
      'date': _formatDate(date),
      'weight': weight,
      'type': type
    });

    await loadEntries(date);
  }

  Future<void> updateEntry(
      DiaryEntry entry, int newWeight, String newType) async {
    await database.update(
      'diary',
      {'weight': newWeight, 'type': newType},
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    await loadEntries(_selectedDate);
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    await database.delete(
      'diary',
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    await loadEntries(_selectedDate);
  }

  Future<void> deleteRelatedEntries(int foodId) async {
    await database.delete('diary', where: 'food_id = ?', whereArgs: [foodId]);
    _entries = _entries.where((entry) => entry.food.id != foodId).toList();
    notifyListeners();
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
