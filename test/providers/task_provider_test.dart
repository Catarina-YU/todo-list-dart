import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/category.dart' as model;
import 'package:mobile_todo/models/task.dart';
import 'package:mobile_todo/providers/task_provider.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:mobile_todo/repositories/task_repository.dart';
import 'package:mobile_todo/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TaskProvider Tests', () {
    late Database testDb;
    late TaskRepository taskRepo;
    late CategoryRepository categoryRepo;
    late FakeNotificationService notificationService;
    late TaskProvider taskProvider;

    setUp(() async {
      testDb = await AppDatabase.openTestDatabase(
        dbPath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
      taskRepo = TaskRepository(db: testDb);
      categoryRepo = CategoryRepository(db: testDb);
      notificationService = FakeNotificationService();
      taskProvider = TaskProvider(
        taskRepository: taskRepo,
        notificationService: notificationService,
      );
      await taskProvider.loadTasks();
    });

    tearDown(() async {
      await testDb.close();
    });

    test('1. loadTasks loads tasks successfully', () async {
      expect(taskProvider.allTasks, isEmpty);
      expect(taskProvider.tasks, isEmpty);
      expect(taskProvider.isLoading, false);
      expect(taskProvider.errorMessage, isNull);
    });

    test('2. createTask adds task to repository and local state', () async {
      final now = DateTime.now();
      final task = Task(
        title: 'Nova Tarefa',
        description: 'Teste de criação',
        createdAt: now,
      );

      final created = await taskProvider.createTask(task);

      expect(created.id, isNotNull);
      expect(taskProvider.allTasks.length, 1);
      expect(taskProvider.allTasks.first.title, 'Nova Tarefa');
    });

    test('3. getTaskById retrieves task correctly', () async {
      final now = DateTime.now();
      final task = Task(title: 'Buscar por ID', createdAt: now);
      final created = await taskProvider.createTask(task);

      final fetched = await taskProvider.getTaskById(created.id!);

      expect(fetched, isNotNull);
      expect(fetched?.title, 'Buscar por ID');
    });

    test('4. updateTask modifies existing task', () async {
      final now = DateTime.now();
      final task = Task(title: 'Tarefa Antiga', createdAt: now);
      final created = await taskProvider.createTask(task);

      final updated = created.copyWith(title: 'Tarefa Atualizada');
      final success = await taskProvider.updateTask(updated);

      expect(success, true);
      expect(taskProvider.allTasks.first.title, 'Tarefa Atualizada');
    });

    test('5. toggleTaskCompletion changes completed state', () async {
      final now = DateTime.now();
      final task = Task(title: 'Tarefa Pendente', createdAt: now);
      final created = await taskProvider.createTask(task);

      expect(created.completed, false);

      await taskProvider.toggleTaskCompletion(created.id!, true);

      expect(taskProvider.allTasks.first.completed, true);
    });

    test('6. deleteTask removes task from repository and state', () async {
      final now = DateTime.now();
      final task = Task(title: 'Para Excluir', createdAt: now);
      final created = await taskProvider.createTask(task);

      expect(taskProvider.allTasks.length, 1);

      final success = await taskProvider.deleteTask(created.id!);

      expect(success, true);
      expect(taskProvider.allTasks, isEmpty);
    });

    test('7. status filter: all tasks', () async {
      final now = DateTime.now();
      await taskProvider.createTask(Task(title: 'Pendente', completed: false, createdAt: now));
      await taskProvider.createTask(Task(title: 'Concluída', completed: true, createdAt: now));

      taskProvider.setStatusFilter(TaskStatusFilter.all);

      expect(taskProvider.tasks.length, 2);
    });

    test('8. status filter: pending tasks only', () async {
      final now = DateTime.now();
      await taskProvider.createTask(Task(title: 'Pendente', completed: false, createdAt: now));
      await taskProvider.createTask(Task(title: 'Concluída', completed: true, createdAt: now));

      taskProvider.setStatusFilter(TaskStatusFilter.pending);

      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Pendente');
    });

    test('9. status filter: completed tasks only', () async {
      final now = DateTime.now();
      await taskProvider.createTask(Task(title: 'Pendente', completed: false, createdAt: now));
      await taskProvider.createTask(Task(title: 'Concluída', completed: true, createdAt: now));

      taskProvider.setStatusFilter(TaskStatusFilter.completed);

      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Concluída');
    });

    test('10. filter by category should return only tasks with matching categoryId', () async {
      final cat1 = await categoryRepo.createCategory(const model.Category(name: 'Trabalho'));
      final cat2 = await categoryRepo.createCategory(const model.Category(name: 'Pessoal'));

      await taskProvider.createTask(Task(title: 'Task Trabalho', categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Task Pessoal', categoryId: cat2.id, createdAt: DateTime.now()));

      taskProvider.setCategoryFilter(cat1.id);

      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Task Trabalho');
    });

    test('11. combination of status + category filter', () async {
      final cat1 = await categoryRepo.createCategory(const model.Category(name: 'Estudos'));

      await taskProvider.createTask(Task(title: 'Estudar Flutter', completed: false, categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Ler livro', completed: true, categoryId: cat1.id, createdAt: DateTime.now()));

      taskProvider.setStatusFilter(TaskStatusFilter.pending);
      taskProvider.setCategoryFilter(cat1.id);

      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Estudar Flutter');
    });

    test('12. task without category is returned when category filter is null', () async {
      final cat1 = await categoryRepo.createCategory(const model.Category(name: 'Geral'));

      await taskProvider.createTask(Task(title: 'Com Categoria', categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Sem Categoria', categoryId: null, createdAt: DateTime.now()));

      taskProvider.setCategoryFilter(null);
      expect(taskProvider.tasks.length, 2);

      taskProvider.setCategoryFilter(cat1.id);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Com Categoria');
    });

    test('13. clearFilters resets both filters', () async {
      taskProvider.setStatusFilter(TaskStatusFilter.completed);
      taskProvider.setCategoryFilter(1);

      taskProvider.clearFilters();

      expect(taskProvider.statusFilter, TaskStatusFilter.all);
      expect(taskProvider.selectedCategoryId, isNull);
    });

    test('14. notification scheduled when task has future dueDateTime', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final task = Task(
        title: 'Tarefa com Prazo',
        dueDateTime: futureDate,
        createdAt: DateTime.now(),
      );

      final created = await taskProvider.createTask(task);

      expect(notificationService.scheduledNotifications.containsKey(created.id), true);
      expect(notificationService.scheduledNotifications[created.id]?.title, 'Tarefa com Prazo');
    });

    test('15. onCategoryDeleted handles decoupled category deletion and resets active category filter if matched', () async {
      final cat = await categoryRepo.createCategory(const model.Category(name: 'Faculdade'));
      await taskProvider.createTask(Task(title: 'Atividade 1', categoryId: cat.id, createdAt: DateTime.now()));

      taskProvider.setCategoryFilter(cat.id);
      expect(taskProvider.selectedCategoryId, cat.id);

      await categoryRepo.deleteCategory(cat.id!);
      taskProvider.onCategoryDeleted(cat.id!);

      expect(taskProvider.selectedCategoryId, isNull);
      expect(taskProvider.allTasks.first.categoryId, isNull);
    });
  });
}
