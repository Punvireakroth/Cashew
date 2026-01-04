import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';
import '../../accounts/account_form_screen.dart';
import '../../accounts/account_details_screen.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final l10n = AppLocalizations.of(context)!;

    if (accountState.accounts.isEmpty) {
      return _buildEmptyState(context, accentColor, l10n);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final accountCount = accountState.accounts.length;
        const addCardWidth = 120.0;
        const cardMargin = 12.0;

        // Calculate card width: stretch to fill when only 1 account
        final double cardWidth;
        if (accountCount == 1) {
          cardWidth = constraints.maxWidth - addCardWidth - cardMargin;
        } else {
          cardWidth = 200.0;
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: accountCount + 1,
            itemBuilder: (context, index) {
              if (index == accountCount) {
                return _buildAddAccountCard(context, l10n);
              }
              return _buildAccountCard(
                context,
                ref,
                accountState,
                index,
                accentColor,
                l10n,
                cardWidth,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.noAccounts, style: const TextStyle(color: Colors.black54)),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: Text(l10n.addAccount),
            style: TextButton.styleFrom(foregroundColor: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AccountFormScreen()),
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
              l10n.account,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
    Color accentColor,
    AppLocalizations l10n,
    double cardWidth,
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
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? accentColor.withOpacity(0.15) : Colors.white,
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
                    color: index % 2 == 0 ? Colors.grey.shade400 : accentColor,
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
              l10n.transactionsCount(transactionCount),
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
