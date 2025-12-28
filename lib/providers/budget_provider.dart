import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../services/database_service.dart';

/// Data class to hold budget with its spending info
class BudgetWithSpent {
  final Budget budget;
  final List<String> categoryIds;
  final double spent;
  final double remaining;
  final double percentage;
  final int daysRemaining;
  final double dailyAllowance;

  const BudgetWithSpent({
    required this.budget,
    required this.categoryIds,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.daysRemaining,
    required this.dailyAllowance,
  });

  bool get isOverBudget => percentage > 100;
  bool get isWarning => percentage >= 80 && percentage <= 100;
  bool get isOnTrack => percentage < 80;
}

/// State class for budget management
class BudgetState {
  final List<BudgetWithSpent> budgets;
  final bool isLoading;
  final String? error;

  const BudgetState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    List<BudgetWithSpent>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get only active budgets (current period)
  List<BudgetWithSpent> get activeBudgets {
    final now = DateTime.now().millisecondsSinceEpoch;
    return budgets.where((b) {
      return b.budget.startDate <= now && b.budget.endDate >= now;
    }).toList();
  }
}

/// Budget provider using Riverpod StateNotifier
class BudgetNotifier extends StateNotifier<BudgetState> {
  final DatabaseService _db;

  BudgetNotifier(this._db) : super(const BudgetState());

  /// Load all budgets with their spending info from database
  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final budgets = await _db.getBudgets();
      final budgetsWithSpent = <BudgetWithSpent>[];

      for (final budget in budgets) {
        // Get categories linked to this budget
        final categoryIds = await _db.getBudgetCategoryIds(budget.id);

        // Calculate spent amount based on linked categories and account
        final spent = categoryIds.isEmpty
            ? 0.0
            : await _db.getBudgetSpent(
                budget.startDate,
                budget.endDate,
                categoryIds,
                accountId: budget.accountId,
              );

        final remaining = budget.limitAmount - spent;
        final percentage = budget.limitAmount > 0
            ? (spent / budget.limitAmount) * 100
            : 0.0;

        // Calculate days remaining
        final now = DateTime.now();
        final endDate = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
        final daysRemaining = endDate.difference(now).inDays;

        // Calculate daily allowance
        final dailyAllowance = daysRemaining > 0
            ? remaining / daysRemaining
            : 0.0;

        budgetsWithSpent.add(
          BudgetWithSpent(
            budget: budget,
            categoryIds: categoryIds,
            spent: spent,
            remaining: remaining > 0 ? remaining : 0,
            percentage: percentage,
            daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
            dailyAllowance: dailyAllowance > 0 ? dailyAllowance : 0,
          ),
        );
      }

      state = state.copyWith(budgets: budgetsWithSpent, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load budgets: ${e.toString()}',
      );
    }
  }

  /// Create a new budget with linked categories
  Future<bool> createBudget(Budget budget, List<String> categoryIds) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if budget name already exists
      final exists = await _db.budgetExistsByName(budget.name);
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A budget with this name already exists',
        );
        return false;
      }

      // Validate at least one category
      if (categoryIds.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please select at least one category',
        );
        return false;
      }

      await _db.insertBudget(budget);
      await _db.setBudgetCategories(budget.id, categoryIds);

      // Reload budgets to get updated list with spending info
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update an existing budget with linked categories
  Future<bool> updateBudget(Budget budget, List<String> categoryIds) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if budget name exists (excluding current budget)
      final exists = await _db.budgetExistsByName(
        budget.name,
        excludeId: budget.id,
      );
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A budget with this name already exists',
        );
        return false;
      }

      // Validate at least one category
      if (categoryIds.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please select at least one category',
        );
        return false;
      }

      await _db.updateBudget(budget);
      await _db.setBudgetCategories(budget.id, categoryIds);

      // Reload budgets to get updated list
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get category IDs for a budget
  Future<List<String>> getBudgetCategoryIds(String budgetId) async {
    return await _db.getBudgetCategoryIds(budgetId);
  }

  /// Delete a budget by id
  Future<bool> deleteBudget(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.deleteBudget(id);

      // Reload budgets to get updated list
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get a budget by id
  BudgetWithSpent? getBudgetById(String id) {
    try {
      return state.budgets.firstWhere((b) => b.budget.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for BudgetNotifier
final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>(
  (ref) => BudgetNotifier(DatabaseService()),
);

/// Convenience provider for active budgets count
final activeBudgetsCountProvider = Provider<int>((ref) {
  final state = ref.watch(budgetProvider);
  return state.activeBudgets.length;
});

/// Convenience provider for first active budget (for home screen display)
final primaryBudgetProvider = Provider<BudgetWithSpent?>((ref) {
  final state = ref.watch(budgetProvider);
  final active = state.activeBudgets;
  return active.isNotEmpty ? active.first : null;
});
