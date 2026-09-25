import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/category.dart' as model;
import 'package:mobile_todo/models/task.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:mobile_todo/repositories/task_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('CategoryRepository Tests', () {
    late Database testDb;
    late CategoryRepository categoryRepo;
    late TaskRepository taskRepo;

    setUp(() async {
      testDb = await AppDatabase.openTestDatabase(
        dbPath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
      categoryRepo = CategoryRepository(db: testDb);
      taskRepo = TaskRepository(db: testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('1. should create category and assign generated id', () async {
      const category = model.Category(name: 'Estudos');
      final created = await categoryRepo.createCategory(category);

      expect(created.id, isNotNull);
      expect(created.id, greaterThan(0));
      expect(created.name, 'Estudos');
    });

    test('1b. should throw ArgumentError when category name is empty', () async {
      const category = model.Category(name: '   ');

      expect(
        () async => await categoryRepo.createCategory(category),
        throwsArgumentError,
      );
    });

    test('2. should retrieve category by id', () async {
      final created = await categoryRepo.createCategory(const model.Category(name: 'Trabalho'));
      final found = await categoryRepo.getCategoryById(created.id!);

      expect(found, isNotNull);
      expect(found?.id, created.id);
      expect(found?.name, 'Trabalho');
    });

    test('2b. should return null when retrieving non-existent category id', () async {
      final found = await categoryRepo.getCategoryById(999);
      expect(found, isNull);
    });

    test('3. should retrieve all categories ordered by name', () async {
      await categoryRepo.createCategory(const model.Category(name: 'Trabalho'));
      await categoryRepo.createCategory(const model.Category(name: 'Academia'));
      await categoryRepo.createCategory(const model.Category(name: 'Casa'));

      final list = await categoryRepo.getAllCategories();
      expect(list.length, 3);
      expect(list.map((c) => c.name).toList(), ['Academia', 'Casa', 'Trabalho']);
    });

    test('4. should rename / update category', () async {
      final created = await categoryRepo.createCategory(const model.Category(name: 'Pessoal'));
      final updated = created.copyWith(name: 'Projetos Pessoais');

      final success = await categoryRepo.updateCategory(updated);
      expect(success, true);

      final fetched = await categoryRepo.getCategoryById(created.id!);
      expect(fetched?.name, 'Projetos Pessoais');
    });

    test('4b. should return false when updating non-existent category id', () async {
      const nonExistent = model.Category(id: 999, name: 'Nova Categoria');
      final success = await categoryRepo.updateCategory(nonExistent);

      expect(success, false);
    });

    test('5. should delete category by id', () async {
      final created = await categoryRepo.createCategory(const model.Category(name: 'Temporária'));
      final deleted = await categoryRepo.deleteCategory(created.id!);

      expect(deleted, true);
      final fetched = await categoryRepo.getCategoryById(created.id!);
      expect(fetched, isNull);
    });

    test('6 & 7. should verify tasks remain and category_id becomes NULL after category deletion', () async {
      final category = await categoryRepo.createCategory(const model.Category(name: 'Projetos'));

      final task = await taskRepo.createTask(
        Task(
          title: 'Implementar Repositórios',
          createdAt: DateTime.now(),
          categoryId: category.id,
        ),
      );

      expect(task.categoryId, category.id);

      // Delete category
      final deleted = await categoryRepo.deleteCategory(category.id!);
      expect(deleted, true);

      // Verify task still exists and category_id is set to null
      final fetchedTask = await taskRepo.getTaskById(task.id!);
      expect(fetchedTask, isNotNull);
      expect(fetchedTask?.id, task.id);
      expect(fetchedTask?.categoryId, isNull);
    });
  });
}
