import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/models/category.dart';
import 'package:mobile_todo/models/task.dart';

void main() {
  group('Category Model Tests', () {
    test('should create Category instance with required fields', () {
      const category = Category(name: 'Trabalho');

      expect(category.id, isNull);
      expect(category.name, 'Trabalho');
    });

    test('should create Category instance with id', () {
      const category = Category(id: 1, name: 'Estudos');

      expect(category.id, 1);
      expect(category.name, 'Estudos');
    });

    test('should support copyWith', () {
      const category = Category(id: 1, name: 'Pessoal');
      final updated = category.copyWith(name: 'Casa');

      expect(updated.id, 1);
      expect(updated.name, 'Casa');
    });

    test('should support value equality', () {
      const cat1 = Category(id: 1, name: 'Trabalho');
      const cat2 = Category(id: 1, name: 'Trabalho');

      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
    });
  });

  group('Task Model Tests', () {
    final now = DateTime.now();

    test('should create Task instance with minimum required fields', () {
      final task = Task(
        title: 'Comprar leite',
        createdAt: now,
      );

      expect(task.id, isNull);
      expect(task.title, 'Comprar leite');
      expect(task.description, isNull);
      expect(task.completed, false);
      expect(task.dueDateTime, isNull);
      expect(task.createdAt, now);
      expect(task.categoryId, isNull);
    });

    test('should create Task instance with all fields', () {
      final due = now.add(const Duration(days: 1));
      final task = Task(
        id: 10,
        title: 'Estudar Flutter',
        description: 'Revisar modelos e provider',
        completed: true,
        dueDateTime: due,
        createdAt: now,
        categoryId: 2,
      );

      expect(task.id, 10);
      expect(task.title, 'Estudar Flutter');
      expect(task.description, 'Revisar modelos e provider');
      expect(task.completed, true);
      expect(task.dueDateTime, due);
      expect(task.createdAt, now);
      expect(task.categoryId, 2);
    });

    test('should support copyWith and field clearing', () {
      final due = now.add(const Duration(days: 2));
      final task = Task(
        id: 1,
        title: 'Tarefa original',
        description: 'Descrição antiga',
        dueDateTime: due,
        createdAt: now,
        categoryId: 5,
      );

      final updated = task.copyWith(
        title: 'Tarefa modificada',
        completed: true,
        clearDescription: true,
        clearCategoryId: true,
      );

      expect(updated.id, 1);
      expect(updated.title, 'Tarefa modificada');
      expect(updated.description, isNull);
      expect(updated.completed, true);
      expect(updated.dueDateTime, due);
      expect(updated.categoryId, isNull);
    });

    test('should support value equality', () {
      final task1 = Task(
        id: 1,
        title: 'Testar',
        createdAt: now,
      );

      final task2 = Task(
        id: 1,
        title: 'Testar',
        createdAt: now,
      );

      expect(task1, equals(task2));
      expect(task1.hashCode, equals(task2.hashCode));
    });
  });
}
