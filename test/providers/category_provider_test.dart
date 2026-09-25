import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/category.dart';
import 'package:mobile_todo/providers/category_provider.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('CategoryProvider Tests', () {
    late Database testDb;
    late CategoryRepository categoryRepo;
    late CategoryProvider categoryProvider;

    setUp(() async {
      testDb = await AppDatabase.openTestDatabase(
        dbPath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
      categoryRepo = CategoryRepository(db: testDb);
      categoryProvider = CategoryProvider(categoryRepository: categoryRepo);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('1. initial loading loads categories and updates state', () async {
      expect(categoryProvider.categories, isEmpty);
      expect(categoryProvider.isLoading, false);

      await categoryProvider.loadCategories();

      expect(categoryProvider.categories, isEmpty);
      expect(categoryProvider.isLoading, false);
      expect(categoryProvider.errorMessage, isNull);
    });

    test('2. should create category and update provider state', () async {
      const category = Category(name: 'Estudos');
      final created = await categoryProvider.createCategory(category);

      expect(created.id, isNotNull);
      expect(categoryProvider.categories.length, 1);
      expect(categoryProvider.categories.first.name, 'Estudos');
    });

    test('3. should update/rename category in provider state and database', () async {
      final created = await categoryProvider.createCategory(
        const Category(name: 'Trabalho'),
      );

      final updated = created.copyWith(name: 'Trabalho & Projetos');
      final success = await categoryProvider.updateCategory(updated);

      expect(success, true);
      expect(categoryProvider.categories.first.name, 'Trabalho & Projetos');
    });

    test('4. should delete category from provider state and trigger onCategoryDeleted callback', () async {
      final created = await categoryProvider.createCategory(
        const Category(name: 'Casa'),
      );
      expect(categoryProvider.categories.length, 1);

      int? deletedCategoryId;
      final deleted = await categoryProvider.deleteCategory(
        created.id!,
        onCategoryDeleted: (catId) {
          deletedCategoryId = catId;
        },
      );

      expect(deleted, true);
      expect(categoryProvider.categories, isEmpty);
      expect(deletedCategoryId, created.id);
    });

    test('5. error handling updates errorMessage and resets isLoading when invalid category name is provided', () async {
      const invalidCategory = Category(name: '   ');

      expect(
        () async => await categoryProvider.createCategory(invalidCategory),
        throwsArgumentError,
      );

      expect(categoryProvider.errorMessage, isNotNull);
      expect(categoryProvider.isLoading, false);
    });

    test('6. listeners are notified when category state changes', () async {
      int listenerCallCount = 0;
      categoryProvider.addListener(() {
        listenerCallCount++;
      });

      await categoryProvider.createCategory(const Category(name: 'Saúde'));
      expect(listenerCallCount, greaterThan(0));
    });

    test('7. should retrieve category by id', () async {
      final created = await categoryProvider.createCategory(
        const Category(name: 'Finanças'),
      );

      final fetched = await categoryProvider.getCategoryById(created.id!);
      expect(fetched, isNotNull);
      expect(fetched?.name, 'Finanças');
    });
  });
}
