import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/category.dart' as model;
import 'package:mobile_todo/providers/category_provider.dart';
import 'package:mobile_todo/providers/task_provider.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:mobile_todo/repositories/task_repository.dart';
import 'package:mobile_todo/screens/category_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget createTestableWidget({
  required TaskProvider taskProvider,
  required CategoryProvider categoryProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
      ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('CategoryListScreen Widget Tests', () {
    late Database testDb;
    late TaskRepository taskRepo;
    late CategoryRepository categoryRepo;
    late TaskProvider taskProvider;
    late CategoryProvider categoryProvider;

    setUp(() async {
      testDb = await AppDatabase.openTestDatabase(
        dbPath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
      taskRepo = TaskRepository(db: testDb);
      categoryRepo = CategoryRepository(db: testDb);
      taskProvider = TaskProvider(taskRepository: taskRepo);
      categoryProvider = CategoryProvider(categoryRepository: categoryRepo);
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('1. renders empty state when no categories exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const CategoryListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gerenciar Categorias'), findsOneWidget);
      expect(find.text('Nenhuma categoria cadastrada.'), findsOneWidget);
    });

    testWidgets('2. renders list when categories exist', (WidgetTester tester) async {
      await categoryRepo.createCategory(const model.Category(name: 'Trabalho'));

      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const CategoryListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trabalho'), findsOneWidget);
    });

    testWidgets('3. opens category creation dialog when FAB is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const CategoryListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Nova Categoria'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('4. shows delete confirmation dialog when delete icon is pressed', (WidgetTester tester) async {
      await categoryRepo.createCategory(const model.Category(name: 'Pessoal'));

      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const CategoryListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final deleteIcon = find.byIcon(Icons.delete);
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('Excluir Categoria'), findsOneWidget);
      expect(find.textContaining('Deseja excluir a categoria "Pessoal"?'), findsOneWidget);
    });
  });
}
