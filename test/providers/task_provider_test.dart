import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/category.dart';
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
    });

    tearDown(() async {
      await testDb.close();
    });

    test('1. initial loading loads empty or existing tasks and updates state', () async {
      expect(taskProvider.allTasks, isEmpty);
      expect(taskProvider.tasks, isEmpty);
      expect(taskProvider.isLoading, false);

      await taskProvider.loadTasks();

      expect(taskProvider.allTasks, isEmpty);
      expect(taskProvider.isLoading, false);
      expect(taskProvider.errorMessage, isNull);
    });

    test('2. should create task and update provider state', () async {
      final task = Task(title: 'Estudar State Management', createdAt: DateTime.now());
      final created = await taskProvider.createTask(task);

      expect(created.id, isNotNull);
      expect(taskProvider.allTasks.length, 1);
      expect(taskProvider.allTasks.first.title, 'Estudar State Management');
      expect(taskProvider.tasks.length, 1);
    });

    test('3. should update task in provider state and database', () async {
      final created = await taskProvider.createTask(
        Task(title: 'Tarefa Inicial', createdAt: DateTime.now()),
      );

      final updatedTask = created.copyWith(title: 'Tarefa Modificada', description: 'Nova desc');
      final success = await taskProvider.updateTask(updatedTask);

      expect(success, true);
      expect(taskProvider.allTasks.first.title, 'Tarefa Modificada');
      expect(taskProvider.allTasks.first.description, 'Nova desc');
    });

    test('4. should delete task from provider state and database', () async {
      final created = await taskProvider.createTask(
        Task(title: 'A ser removida', createdAt: DateTime.now()),
      );
      expect(taskProvider.allTasks.length, 1);

      final deleted = await taskProvider.deleteTask(created.id!);

      expect(deleted, true);
      expect(taskProvider.allTasks, isEmpty);
      expect(taskProvider.tasks, isEmpty);
    });

    test('5. should conclude task (toggle to completed = true)', () async {
      final created = await taskProvider.createTask(
        Task(title: 'Comprar leite', completed: false, createdAt: DateTime.now()),
      );

      final success = await taskProvider.toggleTaskCompletion(created.id!, true);

      expect(success, true);
      expect(taskProvider.allTasks.first.completed, true);
    });

    test('6. should reopen task (toggle to completed = false)', () async {
      final created = await taskProvider.createTask(
        Task(title: 'Comprar café', completed: true, createdAt: DateTime.now()),
      );

      final success = await taskProvider.toggleTaskCompletion(created.id!, false);

      expect(success, true);
      expect(taskProvider.allTasks.first.completed, false);
    });

    test('7. filter "all" should return both pending and completed tasks', () async {
      await taskProvider.createTask(Task(title: 'Pend 1', completed: false, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Conc 1', completed: true, createdAt: DateTime.now()));

      taskProvider.setStatusFilter(TaskStatusFilter.all);

      expect(taskProvider.allTasks.length, 2);
      expect(taskProvider.tasks.length, 2);
    });

    test('8. filter "pending" should return only pending tasks', () async {
      await taskProvider.createTask(Task(title: 'Pend 1', completed: false, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Conc 1', completed: true, createdAt: DateTime.now()));

      taskProvider.setStatusFilter(TaskStatusFilter.pending);

      expect(taskProvider.allTasks.length, 2);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Pend 1');
    });

    test('9. filter "completed" should return only completed tasks', () async {
      await taskProvider.createTask(Task(title: 'Pend 1', completed: false, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Conc 1', completed: true, createdAt: DateTime.now()));

      taskProvider.setStatusFilter(TaskStatusFilter.completed);

      expect(taskProvider.allTasks.length, 2);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Conc 1');
    });

    test('10. filter by category should return only tasks with matching categoryId', () async {
      final cat1 = await categoryRepo.createCategory(const Category(name: 'Trabalho'));
      final cat2 = await categoryRepo.createCategory(const Category(name: 'Pessoal'));

      await taskProvider.createTask(Task(title: 'Task Trabalho', categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Task Pessoal', categoryId: cat2.id, createdAt: DateTime.now()));

      taskProvider.setCategoryFilter(cat1.id);

      expect(taskProvider.allTasks.length, 2);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Task Trabalho');
    });

    test('11. combination of status + category filter', () async {
      final cat1 = await categoryRepo.createCategory(const Category(name: 'Estudos'));

      await taskProvider.createTask(Task(title: 'Estudar Flutter', completed: false, categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Ler livro', completed: true, categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Outra pendente sem cat', completed: false, createdAt: DateTime.now()));

      taskProvider.setStatusFilter(TaskStatusFilter.pending);
      taskProvider.setCategoryFilter(cat1.id);

      expect(taskProvider.allTasks.length, 3);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Estudar Flutter');
    });

    test('12. task without category is returned when category filter is null', () async {
      final cat1 = await categoryRepo.createCategory(const Category(name: 'Geral'));

      await taskProvider.createTask(Task(title: 'Com Categoria', categoryId: cat1.id, createdAt: DateTime.now()));
      await taskProvider.createTask(Task(title: 'Sem Categoria', categoryId: null, createdAt: DateTime.now()));

      taskProvider.setCategoryFilter(null);
      expect(taskProvider.tasks.length, 2);

      taskProvider.setCategoryFilter(cat1.id);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Com Categoria');
    });

    test('13. error handling updates errorMessage and resets isLoading', () async {
      final invalidTask = Task(title: '   ', createdAt: DateTime.now());

      expect(
        () async => await taskProvider.createTask(invalidTask),
        throwsArgumentError,
      );

      expect(taskProvider.errorMessage, isNotNull);
      expect(taskProvider.isLoading, false);
    });

    test('14. listeners are notified when state or filters change', () async {
      int listenerCallCount = 0;
      taskProvider.addListener(() {
        listenerCallCount++;
      });

      await taskProvider.createTask(Task(title: 'Test Notification', createdAt: DateTime.now()));
      expect(listenerCallCount, greaterThan(0));

      final initialCount = listenerCallCount;
      taskProvider.setStatusFilter(TaskStatusFilter.pending);
      expect(listenerCallCount, initialCount + 1);

      taskProvider.setStatusFilter(TaskStatusFilter.pending);
      expect(listenerCallCount, initialCount + 1);
    });

    test('15. onCategoryDeleted handles decoupled category deletion and resets active category filter if matched', () async {
      final cat = await categoryRepo.createCategory(const Category(name: 'Faculdade'));
      await taskProvider.createTask(Task(title: 'Atividade 1', categoryId: cat.id, createdAt: DateTime.now()));

      taskProvider.setCategoryFilter(cat.id);
      expect(taskProvider.selectedCategoryId, cat.id);
      expect(taskProvider.tasks.length, 1);

      await categoryRepo.deleteCategory(cat.id!);
      taskProvider.onCategoryDeleted(cat.id!);

      expect(taskProvider.selectedCategoryId, isNull);
      expect(taskProvider.allTasks.first.categoryId, isNull);
      expect(taskProvider.tasks.length, 1);
    });

    test('16. creating task with future dueDateTime schedules notification', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final created = await taskProvider.createTask(
        Task(
          title: 'Tarefa Futura',
          dueDateTime: futureDate,
          createdAt: DateTime.now(),
        ),
      );

      expect(notificationService.scheduledNotifications.containsKey(created.id), true);
    });

    test('17. creating task without dueDateTime or in past does not schedule notification', () async {
      final pastDate = DateTime.now().subtract(const Duration(hours: 2));

      final created1 = await taskProvider.createTask(
        Task(title: 'Sem Vencimento', createdAt: DateTime.now()),
      );
      final created2 = await taskProvider.createTask(
        Task(title: 'Vencimento Passado', dueDateTime: pastDate, createdAt: DateTime.now()),
      );

      expect(notificationService.scheduledNotifications.containsKey(created1.id), false);
      expect(notificationService.scheduledNotifications.containsKey(created2.id), false);
    });

    test('18. updating task dueDateTime reschedules notification', () async {
      final futureDate1 = DateTime.now().add(const Duration(days: 1));
      final futureDate2 = DateTime.now().add(const Duration(days: 2));

      final created = await taskProvider.createTask(
        Task(title: 'Tarefa', dueDateTime: futureDate1, createdAt: DateTime.now()),
      );

      expect(notificationService.scheduledNotifications[created.id!]?.scheduledDate, futureDate1);

      final updated = created.copyWith(dueDateTime: futureDate2);
      await taskProvider.updateTask(updated);

      expect(notificationService.scheduledNotifications[created.id!]?.scheduledDate, futureDate2);
    });

    test('19. concluding task cancels notification', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final created = await taskProvider.createTask(
        Task(title: 'Tarefa', dueDateTime: futureDate, createdAt: DateTime.now()),
      );

      expect(notificationService.scheduledNotifications.containsKey(created.id), true);

      await taskProvider.toggleTaskCompletion(created.id!, true);

      expect(notificationService.scheduledNotifications.containsKey(created.id), false);
    });

    test('20. reopening task with future dueDateTime reschedules notification', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final created = await taskProvider.createTask(
        Task(title: 'Tarefa', completed: true, dueDateTime: futureDate, createdAt: DateTime.now()),
      );

      expect(notificationService.scheduledNotifications.containsKey(created.id), false);

      await taskProvider.toggleTaskCompletion(created.id!, false);

      expect(notificationService.scheduledNotifications.containsKey(created.id), true);
    });

    test('21. deleting task cancels notification', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final created = await taskProvider.createTask(
        Task(title: 'A ser excluída', dueDateTime: futureDate, createdAt: DateTime.now()),
      );

      expect(notificationService.scheduledNotifications.containsKey(created.id), true);

      await taskProvider.deleteTask(created.id!);

      expect(notificationService.scheduledNotifications.containsKey(created.id), false);
    });

    test('22. clearing dueDateTime in updateTask cancels notification', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final created = await taskProvider.createTask(
        Task(title: 'Tarefa', dueDateTime: futureDate, createdAt: DateTime.now()),
      );

      expect(notificationService.scheduledNotifications.containsKey(created.id), true);

      final updated = created.copyWith(clearDueDateTime: true);
      await taskProvider.updateTask(updated);

      expect(notificationService.scheduledNotifications.containsKey(created.id), false);
    });
  });
}
