import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';

enum TaskStatusFilter {
  all,
  pending,
  completed,
}

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;
  final NotificationService? _notificationService;

  List<Task> _allTasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  int? _selectedCategoryId;

  TaskProvider({
    TaskRepository? taskRepository,
    NotificationService? notificationService,
  })  : _taskRepository = taskRepository ?? TaskRepository(),
        _notificationService = notificationService;

  /// Indicates whether an async operation is currently in progress.
  bool get isLoading => _isLoading;

  /// Holds the error message if the last operation failed, or `null` if successful.
  String? get errorMessage => _errorMessage;

  /// Current status filter applied to tasks.
  TaskStatusFilter get statusFilter => _statusFilter;

  /// Current category ID filter applied to tasks (`null` for all categories).
  int? get selectedCategoryId => _selectedCategoryId;

  /// Exposes all persisted tasks loaded from repository (read-only).
  UnmodifiableListView<Task> get allTasks => UnmodifiableListView(_allTasks);

  /// Exposes visible tasks after applying current status and category filters (read-only).
  UnmodifiableListView<Task> get tasks {
    final filtered = _allTasks.where((task) {
      final matchesStatus = switch (_statusFilter) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.pending => !task.completed,
        TaskStatusFilter.completed => task.completed,
      };

      final matchesCategory =
          _selectedCategoryId == null || task.categoryId == _selectedCategoryId;

      return matchesStatus && matchesCategory;
    }).toList();

    return UnmodifiableListView(filtered);
  }

  /// Updates the status filter and notifies listeners if changed.
  void setStatusFilter(TaskStatusFilter filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    notifyListeners();
  }

  /// Updates the category filter and notifies listeners if changed.
  void setCategoryFilter(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Resets status filter to [TaskStatusFilter.all] and category filter to `null`.
  void clearFilters() {
    if (_statusFilter == TaskStatusFilter.all && _selectedCategoryId == null) return;
    _statusFilter = TaskStatusFilter.all;
    _selectedCategoryId = null;
    notifyListeners();
  }

  /// Loads all tasks from the repository into memory.
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTasks = await _taskRepository.getAllTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Persists a new [task] through the repository and updates local state.
  Future<Task> createTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdTask = await _taskRepository.createTask(task);
      _allTasks = [createdTask, ..._allTasks];

      if (createdTask.id != null &&
          createdTask.dueDateTime != null &&
          createdTask.dueDateTime!.isAfter(DateTime.now()) &&
          !createdTask.completed) {
        await _notificationService?.scheduleNotification(
          id: createdTask.id!,
          title: 'Lembrete de Tarefa',
          body: createdTask.title,
          scheduledDate: createdTask.dueDateTime!,
        );
      }

      _isLoading = false;
      notifyListeners();
      return createdTask;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Retrieves a task by [id] using the repository.
  Future<Task?> getTaskById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = await _taskRepository.getTaskById(id);
      _isLoading = false;
      notifyListeners();
      return task;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing [task] in repository and local state.
  Future<bool> updateTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (task.id != null) {
        await _notificationService?.cancelNotification(task.id!);
      }

      final success = await _taskRepository.updateTask(task);
      if (success) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = task;
        } else {
          _allTasks = await _taskRepository.getAllTasks();
        }

        if (task.id != null &&
            task.dueDateTime != null &&
            task.dueDateTime!.isAfter(DateTime.now()) &&
            !task.completed) {
          await _notificationService?.scheduleNotification(
            id: task.id!,
            title: 'Lembrete de Tarefa',
            body: task.title,
            scheduledDate: task.dueDateTime!,
          );
        }
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Toggles the completion status of a task by [id].
  Future<bool> toggleTaskCompletion(int id, bool completed) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _taskRepository.toggleTaskCompletion(id, completed);
      if (success) {
        final index = _allTasks.indexWhere((t) => t.id == id);
        if (index != -1) {
          final updatedTask = _allTasks[index].copyWith(completed: completed);
          _allTasks[index] = updatedTask;

          if (completed) {
            await _notificationService?.cancelNotification(id);
          } else if (updatedTask.dueDateTime != null &&
              updatedTask.dueDateTime!.isAfter(DateTime.now())) {
            await _notificationService?.scheduleNotification(
              id: id,
              title: 'Lembrete de Tarefa',
              body: updatedTask.title,
              scheduledDate: updatedTask.dueDateTime!,
            );
          }
        } else {
          _allTasks = await _taskRepository.getAllTasks();
        }
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a task by [id] from repository and local state.
  Future<bool> deleteTask(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notificationService?.cancelNotification(id);
      final success = await _taskRepository.deleteTask(id);
      if (success) {
        _allTasks.removeWhere((t) => t.id == id);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Decoupled handler called when a category is deleted.
  /// Resets the category filter if it matches [categoryId] and updates
  /// affected in-memory tasks to have null categoryId.
  void onCategoryDeleted(int categoryId) {
    bool stateChanged = false;

    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null;
      stateChanged = true;
    }

    for (var i = 0; i < _allTasks.length; i++) {
      if (_allTasks[i].categoryId == categoryId) {
        _allTasks[i] = _allTasks[i].copyWith(clearCategoryId: true);
        stateChanged = true;
      }
    }

    if (stateChanged) {
      notifyListeners();
    }
  }
}
