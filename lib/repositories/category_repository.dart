import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/category.dart' as model;

class CategoryRepository {
  final AppDatabase _appDatabase;
  final Database? _db;

  CategoryRepository({
    AppDatabase? appDatabase,
    Database? db,
  })  : _appDatabase = appDatabase ?? AppDatabase.instance,
        _db = db;

  Future<Database> _getDb() async {
    if (_db != null) return _db;
    return await _appDatabase.database;
  }

  /// Maps a Category object to a SQLite Map
  Map<String, dynamic> _toMap(model.Category category) {
    final map = <String, dynamic>{
      'name': category.name,
    };
    if (category.id != null) {
      map['id'] = category.id;
    }
    return map;
  }

  /// Maps a SQLite Map to a Category object
  model.Category _fromMap(Map<String, dynamic> map) {
    return model.Category(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  /// Persists a new Category. Throws [ArgumentError] if name is empty.
  Future<model.Category> createCategory(model.Category category) async {
    if (category.name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final db = await _getDb();
    final id = await db.insert('categories', _toMap(category));
    return category.copyWith(id: id);
  }

  /// Retrieves all categories ordered by name.
  Future<List<model.Category>> getAllCategories() async {
    final db = await _getDb();
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(_fromMap).toList();
  }

  /// Retrieves a category by ID. Returns `null` if not found.
  Future<model.Category?> getCategoryById(int id) async {
    final db = await _getDb();
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Updates an existing category. Throws [ArgumentError] if ID is null or name is empty.
  /// Returns `true` if updated, `false` if ID does not exist.
  Future<bool> updateCategory(model.Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category ID cannot be null when updating');
    }
    if (category.name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final db = await _getDb();
    final count = await db.update(
      'categories',
      _toMap(category),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return count > 0;
  }

  /// Deletes a category by ID. Linked tasks will have category_id set to NULL by SQLite.
  /// Returns `true` if deleted, `false` if ID does not exist.
  Future<bool> deleteCategory(int id) async {
    final db = await _getDb();
    final count = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
}
