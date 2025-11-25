import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import 'account_provider.dart';

/// Filters for transaction queries
class TransactionFilters {
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final String? accountId;
  final String? type; // 'income', 'expense', or null (all)

  const TransactionFilters({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.accountId,
    this.type,
  });

  TransactionFilters copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    String? accountId,
    String? type,
    bool clearSearch = false,
    bool clearDates = false,
    bool clearCategories = false,
    bool clearAccount = false,
    bool clearType = false,
  }) {
    return TransactionFilters(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      categoryIds: clearCategories ? null : (categoryIds ?? this.categoryIds),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      type: clearType ? null : (type ?? this.type),
    );
  }

  bool get hasActiveFilters =>
      searchQuery != null ||
      startDate != null ||
      endDate != null ||
      (categoryIds != null && categoryIds!.isNotEmpty) ||
      accountId != null ||
      type != null;

  void clear() {}
}

/// State class for transaction management
class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int currentOffset;
  final TransactionFilters filters;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.currentOffset = 0,
    this.filters = const TransactionFilters(),
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? currentOffset,
    TransactionFilters? filters,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      filters: filters ?? this.filters,
    );
  }
}

/// Transaction provider using Riverpod StateNotifier
class TransactionNotifier extends StateNotifier<TransactionState> {
  final DatabaseService _db;
  final Ref _ref;
  static const int _pageSize = 50;

  TransactionNotifier(this._db, this._ref) : super(const TransactionState());

  /// Load initial transactions
  Future<void> loadTransactions({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentOffset: 0,
        transactions: [],
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final transactions = await _db.getFilteredTransactions(
        searchQuery: state.filters.searchQuery,
        startDate: state.filters.startDate?.millisecondsSinceEpoch,
        endDate: state.filters.endDate?.millisecondsSinceEpoch,
        categoryIds: state.filters.categoryIds,
        accountId: state.filters.accountId,
        type: state.filters.type,
        limit: _pageSize,
        offset: 0,
      );

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        currentOffset: transactions.length,
        hasMore: transactions.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: ${e.toString()}',
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreTransactions = await _db.getFilteredTransactions(
        searchQuery: state.filters.searchQuery,
        startDate: state.filters.startDate?.millisecondsSinceEpoch,
        endDate: state.filters.endDate?.millisecondsSinceEpoch,
        categoryIds: state.filters.categoryIds,
        accountId: state.filters.accountId,
        type: state.filters.type,
        limit: _pageSize,
        offset: state.currentOffset,
      );

      final updatedTransactions = List<Transaction>.from([
        ...state.transactions,
        ...moreTransactions,
      ]);

      state = state.copyWith(
        transactions: updatedTransactions,
        isLoadingMore: false,
        currentOffset: updatedTransactions.length,
        hasMore: moreTransactions.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more transactions: ${e.toString()}',
      );
    }
  }

  /// Add a new transaction and update account balance
  Future<bool> addTransaction(
    Transaction transaction,
    Category category,
  ) async {
    try {
      // Get current account
      final account = await _db.getAccountById(transaction.accountId);
      if (account == null) {
        state = state.copyWith(error: 'Account not found');
        return false;
      }

      // Calculate new balance
      final double balanceChange = category.isIncome
          ? transaction.amount
          : -transaction.amount;
      final double newBalance = account.balance + balanceChange;

      // Insert transaction and update account balance in a "transaction"
      await _db.insertTransaction(transaction);
      await _db.updateAccountBalance(account.id, newBalance);

      // Refresh account provider
      _ref.read(accountProvider.notifier).loadAccounts();

      // Reload transactions
      await loadTransactions(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add transaction: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update an existing transaction and recalculate account balance
  Future<bool> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
    Category oldCategory,
    Category newCategory,
  ) async {
    try {
      // Handle account balance changes
      final oldAccount = await _db.getAccountById(oldTransaction.accountId);
      final newAccount = await _db.getAccountById(newTransaction.accountId);

      if (oldAccount == null || newAccount == null) {
        state = state.copyWith(error: 'Account not found');
        return false;
      }

      // Reverse old transaction impact
      final double oldBalanceChange = oldCategory.isIncome
          ? -oldTransaction.amount
          : oldTransaction.amount;

      // Apply new transaction impact
      final double newBalanceChange = newCategory.isIncome
          ? newTransaction.amount
          : -newTransaction.amount;

      // Update balances
      if (oldAccount.id == newAccount.id) {
        // Same account - just adjust the difference
        final totalChange = oldBalanceChange + newBalanceChange;
        await _db.updateAccountBalance(
          oldAccount.id,
          oldAccount.balance + totalChange,
        );
      } else {
        // Different accounts - update both
        await _db.updateAccountBalance(
          oldAccount.id,
          oldAccount.balance + oldBalanceChange,
        );
        await _db.updateAccountBalance(
          newAccount.id,
          newAccount.balance + newBalanceChange,
        );
      }

      // Update transaction
      await _db.updateTransaction(newTransaction);

      // Refresh account provider
      _ref.read(accountProvider.notifier).loadAccounts();

      // Reload transactions
      await loadTransactions(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update transaction: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete a transaction and adjust account balance
  Future<bool> deleteTransaction(
    Transaction transaction,
    Category category,
  ) async {
    try {
      // Get current account
      final account = await _db.getAccountById(transaction.accountId);
      if (account == null) {
        state = state.copyWith(error: 'Account not found');
        return false;
      }

      // Reverse the transaction impact on balance
      final double balanceChange = category.isIncome
          ? -transaction.amount
          : transaction.amount;
      final double newBalance = account.balance + balanceChange;

      // Delete transaction and update account balance
      await _db.deleteTransaction(transaction.id);
      await _db.updateAccountBalance(account.id, newBalance);

      // Refresh account provider
      _ref.read(accountProvider.notifier).loadAccounts();

      // Reload transactions
      await loadTransactions(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete transaction: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update search query
  void setSearchQuery(String? query) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        searchQuery: query,
        clearSearch: query == null || query.isEmpty,
      ),
    );
    loadTransactions(refresh: true);
  }

  /// Update date range filter
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        startDate: startDate,
        endDate: endDate,
        clearDates: startDate == null && endDate == null,
      ),
    );
    loadTransactions(refresh: true);
  }

  /// Update category filter
  void setCategoryFilter(List<String>? categoryIds) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        categoryIds: categoryIds,
        clearCategories: categoryIds == null || categoryIds.isEmpty,
      ),
    );
    loadTransactions(refresh: true);
  }

  /// Update account filter
  void setAccountFilter(String? accountId) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        accountId: accountId,
        clearAccount: accountId == null,
      ),
    );
    loadTransactions(refresh: true);
  }

  /// Update type filter
  void setTypeFilter(String? type) {
    state = state.copyWith(
      filters: state.filters.copyWith(type: type, clearType: type == null),
    );
    loadTransactions(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(filters: const TransactionFilters());
    loadTransactions(refresh: true);
  }

  /// Get transaction by id
  Transaction? getTransactionById(String id) {
    try {
      return state.transactions.firstWhere((tx) => tx.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for TransactionNotifier
final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>(
      (ref) => TransactionNotifier(DatabaseService(), ref),
    );

/// Convenience provider for total count
final transactionCountProvider = FutureProvider<int>((ref) async {
  final db = DatabaseService();
  final state = ref.watch(transactionProvider);
  return await db.getTransactionCount(
    searchQuery: state.filters.searchQuery,
    startDate: state.filters.startDate?.millisecondsSinceEpoch,
    endDate: state.filters.endDate?.millisecondsSinceEpoch,
    categoryIds: state.filters.categoryIds,
    accountId: state.filters.accountId,
    type: state.filters.type,
  );
});
