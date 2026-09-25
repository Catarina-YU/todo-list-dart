import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/category.dart' as model;
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<model.Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoryProvider({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepository();

  /// Indicates whether an async operation is currently in progress.
  bool get isLoading => _isLoading;

  /// Holds the error message if the last operation failed, or `null` if successful.
  String? get errorMessage => _errorMessage;

  /// Exposes loaded categories sorted by name (read-only).
  UnmodifiableListView<model.Category> get categories =>
      UnmodifiableListView(_categories);

  /// Loads all categories from the repository.
  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getAllCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Persists a new [category] through the repository and updates local state.
  Future<model.Category> createCategory(model.Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdCategory =
          await _categoryRepository.createCategory(category);
      _categories = [..._categories, createdCategory]
        ..sort((a, b) => a.name.compareTo(b.name));
      _isLoading = false;
      notifyListeners();
      return createdCategory;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Retrieves a category by [id] using the repository.
  Future<model.Category?> getCategoryById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final category = await _categoryRepository.getCategoryById(id);
      _isLoading = false;
      notifyListeners();
      return category;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing [category] in repository and local state.
  Future<bool> updateCategory(model.Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _categoryRepository.updateCategory(category);
      if (success) {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = category;
          _categories.sort((a, b) => a.name.compareTo(b.name));
        } else {
          _categories = await _categoryRepository.getAllCategories();
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

  /// Deletes a category by [id] from repository and local state.
  /// Optionally triggers [onCategoryDeleted] callback for decoupled task state synchronization.
  Future<bool> deleteCategory(
    int id, {
    void Function(int categoryId)? onCategoryDeleted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _categoryRepository.deleteCategory(id);
      if (success) {
        _categories.removeWhere((c) => c.id == id);
        onCategoryDeleted?.call(id);
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
}
