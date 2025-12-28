import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../utils/currency_formatter.dart';
import '../../accounts/account_form_screen.dart';
import '../../accounts/account_details_screen.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);

    if (accountState.accounts.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accountState.accounts.length + 1,
        itemBuilder: (context, index) {
          if (index == accountState.accounts.length) {
            return _buildAddAccountCard(context);
          }
          return _buildAccountCard(context, ref, accountState, index);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBFA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'No accounts yet',
            style: TextStyle(color: Colors.black54),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Account'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7FD7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AccountFormScreen(),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 32,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              'Account',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    AccountState accountState,
    int index,
  ) {
    final account = accountState.accounts[index];
    final transactionCount = _getTransactionCount(ref, account.id);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AccountDetailsScreen(account: account),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? const Color(0xFFE8EBFA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: index % 2 != 0
              ? Border.all(color: Colors.grey.shade300)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    account.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: index % 2 == 0
                        ? Colors.grey.shade400
                        : const Color(0xFF6B7FD7),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(account.balance),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$transactionCount transactions',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  int _getTransactionCount(WidgetRef ref, String accountId) {
    final transactions = ref.read(transactionProvider).transactions;
    return transactions.where((tx) => tx.accountId == accountId).length;
  }
}

