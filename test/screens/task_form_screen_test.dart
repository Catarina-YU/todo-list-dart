import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/task.dart';
import 'package:mobile_todo/providers/category_provider.dart';
import 'package:mobile_todo/providers/task_provider.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:mobile_todo/repositories/task_repository.dart';
import 'package:mobile_todo/screens/task_form_screen.dart';
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

  group('TaskFormScreen Widget Tests', () {
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

    testWidgets('1. displays validation error when submitting with empty title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const TaskFormScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final saveButton = find.text('Criar Tarefa');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Informe o título da tarefa'), findsOneWidget);
    });

    testWidgets('2. creates a new task when title is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const TaskFormScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextFormField, 'Título *');
      await tester.enterText(titleField, 'Nova Tarefa de Teste');

      final saveButton = find.text('Criar Tarefa');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(taskProvider.allTasks.length, 1);
      expect(taskProvider.allTasks.first.title, 'Nova Tarefa de Teste');
    });

    testWidgets('3. populates fields correctly in edit mode', (WidgetTester tester) async {
      final existingTask = Task(
        id: 1,
        title: 'Tarefa Existente',
        description: 'Descrição de Teste',
        completed: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: TaskFormScreen(task: existingTask),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Editar Tarefa'), findsOneWidget);
      expect(find.text('Tarefa Existente'), findsOneWidget);
      expect(find.text('Descrição de Teste'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
    });

    testWidgets('4. displays existing dueDateTime in edit mode and allows clearing it', (WidgetTester tester) async {
      final dueDate = DateTime(2026, 12, 25, 15, 30);
      final existingTask = Task(
        id: 1,
        title: 'Tarefa com Prazo',
        dueDateTime: dueDate,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: TaskFormScreen(task: existingTask),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('25/12/2026 15:30'), findsOneWidget);

      final clearButton = find.byTooltip('Remover Vencimento');
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Nenhum vencimento definido'), findsOneWidget);
    });
  });
}
