import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String databaseName = 'mobile_todo.db';
  static const int databaseVersion = 1;

  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  factory AppDatabase() {
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, databaseName);

    return await openDatabase(
      dbPath,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NULL,
        completed INTEGER NOT NULL,
        due_date_time TEXT NULL,
        created_at TEXT NOT NULL,
        category_id INTEGER NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      );
    ''');
  }

  /// Opens an in-memory or custom-path database using the same configuration and schema,
  /// primarily useful for automated testing.
  static Future<Database> openTestDatabase({
    String dbPath = inMemoryDatabasePath,
    DatabaseFactory? databaseFactory,
  }) async {
    final factory = databaseFactory ?? databaseFactory;
    if (factory != null) {
      return await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
        ),
      );
    } else {
      return await openDatabase(
        dbPath,
        version: databaseVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    }
  }

  /// Closes the database connection if open.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
