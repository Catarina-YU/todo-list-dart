import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/task.dart';
import 'package:mobile_todo/providers/category_provider.dart';
import 'package:mobile_todo/providers/task_provider.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:mobile_todo/repositories/task_repository.dart';
import 'package:mobile_todo/screens/task_form_screen.dart';
import 'package:mobile_todo/screens/task_list_screen.dart';
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

  group('TaskListScreen Widget Tests', () {
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

    testWidgets('1. renders empty state when no tasks exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const TaskListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Minhas Tarefas'), findsOneWidget);
      expect(find.textContaining('Nenhuma tarefa encontrada'), findsOneWidget);
    });

    testWidgets('2. renders task list when tasks exist', (WidgetTester tester) async {
      await taskRepo.createTask(
        Task(title: 'Estudar Flutter', createdAt: DateTime.now()),
      );

      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const TaskListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Estudar Flutter'), findsOneWidget);
    });

    testWidgets('3. navigates to TaskFormScreen when FAB is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const TaskListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(TaskFormScreen), findsOneWidget);
      expect(find.text('Nova Tarefa'), findsOneWidget);
    });

    testWidgets('4. filter bar correctly filters displayed tasks by status', (WidgetTester tester) async {
      await taskRepo.createTask(Task(title: 'Tarefa Pendente', completed: false, createdAt: DateTime.now()));
      await taskRepo.createTask(Task(title: 'Tarefa Concluída', completed: true, createdAt: DateTime.now()));

      await tester.pumpWidget(
        createTestableWidget(
          taskProvider: taskProvider,
          categoryProvider: categoryProvider,
          child: const TaskListScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tarefa Pendente'), findsOneWidget);
      expect(find.text('Tarefa Concluída'), findsOneWidget);

      taskProvider.setStatusFilter(TaskStatusFilter.pending);
      await tester.pumpAndSettle();

      expect(find.text('Tarefa Pendente'), findsOneWidget);
      expect(find.text('Tarefa Concluída'), findsNothing);
    });
  });
}
