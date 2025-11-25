import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/database_service.dart';

/// State class for account management
class AccountState {
  final List<Account> accounts;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    List<Account>? accounts,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Account provider using Riverpod StateNotifier
class AccountNotifier extends StateNotifier<AccountState> {
  final DatabaseService _db;

  AccountNotifier(this._db) : super(const AccountState());

  /// Load all accounts from database
  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final accounts = await _db.getAccounts();
      state = state.copyWith(
        accounts: accounts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load accounts: ${e.toString()}',
      );
    }
  }

  /// Create a new account
  Future<bool> createAccount(Account account) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if account name already exists
      final exists = await _db.accountExistsByName(account.name);
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'An account with this name already exists',
        );
        return false;
      }

      await _db.insertAccount(account);
      
      // Reload accounts to get updated list
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update an existing account
  Future<bool> updateAccount(Account account) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if account name exists (excluding current account)
      final exists = await _db.accountExistsByName(
        account.name,
        excludeId: account.id,
      );
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'An account with this name already exists',
        );
        return false;
      }

      await _db.updateAccount(account);
      
      // Reload accounts to get updated list
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete an account by id
  Future<bool> deleteAccount(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.deleteAccount(id);
      
      // Reload accounts to get updated list
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('associated transactions')
            ? 'Cannot delete: This account has associated transactions'
            : 'Failed to delete account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get an account by id
  Account? getAccountById(String id) {
    try {
      return state.accounts.firstWhere((acc) => acc.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Calculate total balance across all accounts
  double get totalBalance {
    return state.accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  /// Get accounts by currency
  List<Account> getAccountsByCurrency(String currency) {
    return state.accounts.where((acc) => acc.currency == currency).toList();
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for AccountNotifier
final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>(
  (ref) => AccountNotifier(DatabaseService()),
);

/// Convenience provider for total balance
final totalBalanceProvider = Provider<double>((ref) {
  final state = ref.watch(accountProvider);
  return state.accounts.fold(0.0, (sum, acc) => sum + acc.balance);
});

