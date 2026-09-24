import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/database/app_database.dart';
import 'package:mobile_todo/models/category.dart';
import 'package:mobile_todo/models/task.dart';
import 'package:mobile_todo/repositories/category_repository.dart';
import 'package:mobile_todo/repositories/task_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TaskRepository Tests', () {
    late Database testDb;
    late TaskRepository taskRepo;
    late CategoryRepository categoryRepo;

    setUp(() async {
      testDb = await AppDatabase.openTestDatabase(
        dbPath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
      taskRepo = TaskRepository(db: testDb);
      categoryRepo = CategoryRepository(db: testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('1. should create task and assign generated id', () async {
      final now = DateTime.now();
      final task = Task(
        title: 'Estudar Flutter',
        createdAt: now,
      );

      final created = await taskRepo.createTask(task);
      expect(created.id, isNotNull);
      expect(created.id, greaterThan(0));
      expect(created.title, 'Estudar Flutter');
    });

    test('1b. should throw ArgumentError when creating task with empty title', () async {
      final task = Task(
        title: '   ',
        createdAt: DateTime.now(),
      );

      expect(
        () async => await taskRepo.createTask(task),
        throwsArgumentError,
      );
    });

    test('2. should retrieve created task by id', () async {
      final now = DateTime.now();
      final created = await taskRepo.createTask(
        Task(
          title: 'Ler documentação',
          description: 'Revisar sqflite e provider',
          createdAt: now,
        ),
      );

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched, isNotNull);
      expect(fetched?.id, created.id);
      expect(fetched?.title, 'Ler documentação');
      expect(fetched?.description, 'Revisar sqflite e provider');
    });

    test('3. should retrieve all tasks', () async {
      final now = DateTime.now();
      await taskRepo.createTask(Task(title: 'Tarefa 1', createdAt: now));
      await taskRepo.createTask(Task(title: 'Tarefa 2', createdAt: now.add(const Duration(minutes: 1))));

      final list = await taskRepo.getAllTasks();
      expect(list.length, 2);
    });

    test('4. should update task details', () async {
      final now = DateTime.now();
      final created = await taskRepo.createTask(
        Task(
          title: 'Título Antigo',
          description: 'Descrição Antiga',
          createdAt: now,
        ),
      );

      final updatedTask = created.copyWith(
        title: 'Título Atualizado',
        description: 'Descrição Nova',
        completed: true,
      );

      final success = await taskRepo.updateTask(updatedTask);
      expect(success, true);

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched?.title, 'Título Atualizado');
      expect(fetched?.description, 'Descrição Nova');
      expect(fetched?.completed, true);
    });

    test('5. should update completion status via toggleTaskCompletion', () async {
      final created = await taskRepo.createTask(
        Task(
          title: 'Comprar pão',
          createdAt: DateTime.now(),
        ),
      );

      expect(created.completed, false);

      final success = await taskRepo.toggleTaskCompletion(created.id!, true);
      expect(success, true);

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched?.completed, true);
    });

    test('6. should delete task by id', () async {
      final created = await taskRepo.createTask(
        Task(
          title: 'Tarefa a ser deletada',
          createdAt: DateTime.now(),
        ),
      );

      final deleted = await taskRepo.deleteTask(created.id!);
      expect(deleted, true);

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched, isNull);
    });

    test('7. should persist task without category (categoryId is null)', () async {
      final created = await taskRepo.createTask(
        Task(
          title: 'Tarefa Geral',
          createdAt: DateTime.now(),
          categoryId: null,
        ),
      );

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched?.categoryId, isNull);
    });

    test('8. should persist task with category (categoryId is assigned)', () async {
      final category = await categoryRepo.createCategory(const Category(name: 'Faculdade'));

      final created = await taskRepo.createTask(
        Task(
          title: 'Entregar Atividade',
          createdAt: DateTime.now(),
          categoryId: category.id,
        ),
      );

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched?.categoryId, category.id);
    });

    test('9. should correctly persist and restore DateTime fields (createdAt and dueDateTime)', () async {
      final createdTime = DateTime(2026, 9, 24, 15, 30, 0);
      final dueTime = DateTime(2026, 9, 30, 18, 0, 0);

      final created = await taskRepo.createTask(
        Task(
          title: 'Tarefa com Prazo',
          createdAt: createdTime,
          dueDateTime: dueTime,
        ),
      );

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched?.createdAt, createdTime);
      expect(fetched?.dueDateTime, dueTime);
    });

    test('10. should correctly handle null description', () async {
      final created = await taskRepo.createTask(
        Task(
          title: 'Sem descrição',
          description: null,
          createdAt: DateTime.now(),
        ),
      );

      final fetched = await taskRepo.getTaskById(created.id!);
      expect(fetched?.description, isNull);
    });

    test('11. should return null when searching non-existent task id', () async {
      final fetched = await taskRepo.getTaskById(99999);
      expect(fetched, isNull);
    });

    test('12. should return false when updating completion status for non-existent task id', () async {
      final success = await taskRepo.toggleTaskCompletion(99999, true);
      expect(success, false);
    });
  });
}
