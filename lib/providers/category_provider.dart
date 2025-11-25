import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

/// State class for category management
class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Category provider using Riverpod StateNotifier
class CategoryNotifier extends StateNotifier<CategoryState> {
  final DatabaseService _db;

  CategoryNotifier(this._db) : super(const CategoryState());

  /// Load all categories from database
  Future<void> loadCategories({String? type}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _db.getCategories(type: type);
      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load categories: ${e.toString()}',
      );
    }
  }

  /// Create a new category
  Future<void> createCategory(Category category) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if category name already exists
      final exists = await _db.categoryExistsByName(category.name);
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A category with this name already exists',
        );
        return;
      }

      await _db.insertCategory(category);
      
      // Reload categories to get updated list
      await loadCategories();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create category: ${e.toString()}',
      );
    }
  }

  /// Update an existing category
  Future<void> updateCategory(Category category) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.updateCategory(category);
      
      // Reload categories to get updated list
      await loadCategories();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update category: ${e.toString()}',
      );
    }
  }

  /// Delete a category by id
  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.deleteCategory(id);
      
      // Reload categories to get updated list
      await loadCategories();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('used by existing transactions')
            ? 'Cannot delete: This category is being used by transactions'
            : 'Failed to delete category: ${e.toString()}',
      );
    }
  }

  /// Get a category by id
  Category? getCategoryById(String id) {
    try {
      return state.categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get categories by type (income or expense)
  List<Category> getCategoriesByType(String type) {
    return state.categories.where((cat) => cat.type == type).toList();
  }

  /// Get income categories
  List<Category> get incomeCategories {
    return state.categories.where((cat) => cat.isIncome).toList();
  }

  /// Get expense categories
  List<Category> get expenseCategories {
    return state.categories.where((cat) => cat.isExpense).toList();
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for CategoryNotifier
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) => CategoryNotifier(DatabaseService()),
);

/// Convenience providers for filtered categories
final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final state = ref.watch(categoryProvider);
  return state.categories.where((cat) => cat.isIncome).toList();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final state = ref.watch(categoryProvider);
  return state.categories.where((cat) => cat.isExpense).toList();
});

