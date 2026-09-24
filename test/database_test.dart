import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite_common_ffi for local/unit test runner execution
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Infrastructure Tests', () {
    late Database db;

    setUp(() async {
      db = await AppDatabase.openTestDatabase(
        dbPath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('should open database and verify existence of categories and tasks tables', () async {
      expect(db.isOpen, true);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('categories', 'tasks')",
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();
      expect(tableNames, containsAll(['categories', 'tasks']));
    });

    test('should verify structure of categories table columns', () async {
      final columnsInfo = await db.rawQuery("PRAGMA table_info(categories)");
      final colNames = columnsInfo.map((c) => c['name'] as String).toList();

      expect(colNames, containsAll(['id', 'name']));
    });

    test('should verify structure of tasks table columns', () async {
      final columnsInfo = await db.rawQuery("PRAGMA table_info(tasks)");
      final colNames = columnsInfo.map((c) => c['name'] as String).toList();

      expect(
        colNames,
        containsAll([
          'id',
          'title',
          'description',
          'completed',
          'due_date_time',
          'created_at',
          'category_id',
        ]),
      );
    });

    test('should enforce foreign key ON DELETE SET NULL when deleting a category', () async {
      // 1. Insert a category
      final categoryId = await db.insert('categories', {'name': 'Trabalho'});
      expect(categoryId, greaterThan(0));

      // 2. Insert a task linked to categoryId
      final taskId = await db.insert('tasks', {
        'title': 'Reunião do Projeto',
        'description': 'Discutir entregáveis da sprint',
        'completed': 0,
        'due_date_time': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'category_id': categoryId,
      });

      // 3. Confirm task is linked
      final taskBefore = await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);
      expect(taskBefore.first['category_id'], categoryId);

      // 4. Delete the category
      await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);

      // 5. Verify task remains in tasks table, but category_id is set to NULL
      final taskAfter = await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);
      expect(taskAfter, isNotEmpty);
      expect(taskAfter.first['category_id'], isNull);
    });
  });
}
