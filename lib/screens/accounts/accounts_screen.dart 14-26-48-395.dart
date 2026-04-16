import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_provider.dart';
import '../../widgets/account_card.dart';
import '../../widgets/empty_state.dart';
import 'account_form_screen.dart';

// Export the vertical card
export '../../widgets/account_card.dart' show AccountCardVertical;

/// Screen displaying list of all accounts
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    // Load accounts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).loadAccounts();
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String accountId,
    String accountName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "$accountName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(accountProvider.notifier)
          .deleteAccount(accountId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "$accountName" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = ref.read(accountProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to delete account'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToForm({String? accountId}) async {
    final account = accountId != null
        ? ref.read(accountProvider.notifier).getAccountById(accountId)
        : null;

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Accounts',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
      body: _buildBody(accountState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBody(AccountState state) {
    if (state.isLoading && state.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.accounts.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet,
        message: 'No accounts yet\nCreate your first account to get started',
        actionText: 'Create Account',
        onAction: () => _navigateToForm(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(accountProvider.notifier).loadAccounts(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: state.accounts.length,
        itemBuilder: (context, index) {
          final account = state.accounts[index];
          return Dismissible(
            key: Key(account.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              await _confirmDelete(context, account.id, account.name);
              // Return false because we handle deletion in confirmDelete
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            child: AccountCardVertical(
              account: account,
              onTap: () => _navigateToForm(accountId: account.id),
              transactionCount: 0, // TODO: Get actual transaction count
            ),
          );
        },
      ),
    );
  }
}
