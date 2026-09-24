import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/task.dart';

class TaskRepository {
  final AppDatabase _appDatabase;
  final Database? _db;

  TaskRepository({
    AppDatabase? appDatabase,
    Database? db,
  })  : _appDatabase = appDatabase ?? AppDatabase.instance,
        _db = db;

  Future<Database> _getDb() async {
    if (_db != null) return _db;
    return await _appDatabase.database;
  }

  /// Maps a Task object to a SQLite Map
  Map<String, dynamic> _toMap(Task task) {
    final map = <String, dynamic>{
      'title': task.title,
      'description': task.description,
      'completed': task.completed ? 1 : 0,
      'due_date_time': task.dueDateTime?.toIso8601String(),
      'created_at': task.createdAt.toIso8601String(),
      'category_id': task.categoryId,
    };
    if (task.id != null) {
      map['id'] = task.id;
    }
    return map;
  }

  /// Maps a SQLite Map to a Task object
  Task _fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      completed: (map['completed'] as int) == 1,
      dueDateTime: map['due_date_time'] != null
          ? DateTime.parse(map['due_date_time'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      categoryId: map['category_id'] as int?,
    );
  }

  /// Persists a new Task. Throws [ArgumentError] if title is empty.
  Future<Task> createTask(Task task) async {
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    final db = await _getDb();
    final id = await db.insert('tasks', _toMap(task));
    return task.copyWith(id: id);
  }

  /// Retrieves all tasks from the database.
  Future<List<Task>> getAllTasks() async {
    final db = await _getDb();
    final maps = await db.query('tasks', orderBy: 'created_at DESC');
    return maps.map(_fromMap).toList();
  }

  /// Retrieves a task by ID. Returns `null` if not found.
  Future<Task?> getTaskById(int id) async {
    final db = await _getDb();
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Updates an existing task. Throws [ArgumentError] if ID is null or title is empty.
  /// Returns `true` if updated, `false` if ID does not exist.
  Future<bool> updateTask(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Task ID cannot be null when updating');
    }
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    final db = await _getDb();
    final count = await db.update(
      'tasks',
      _toMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    return count > 0;
  }

  /// Toggles or updates the completion status of a task by ID.
  /// Returns `true` if updated, `false` if ID does not exist.
  Future<bool> toggleTaskCompletion(int id, bool completed) async {
    final db = await _getDb();
    final count = await db.update(
      'tasks',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Deletes a task by ID.
  /// Returns `true` if deleted, `false` if ID does not exist.
  Future<bool> deleteTask(int id) async {
    final db = await _getDb();
    final count = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
}
