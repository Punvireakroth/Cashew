import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/transaction_item.dart';
import '../../transactions/transactions_screen.dart';

class TransactionTabs extends ConsumerStatefulWidget {
  const TransactionTabs({super.key});

  @override
  ConsumerState<TransactionTabs> createState() => _TransactionTabsState();
}

class _TransactionTabsState extends ConsumerState<TransactionTabs> {
  String _selectedType = 'All';

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildTabBar(accentColor, l10n),
        const SizedBox(height: 16),
        _buildTransactionList(transactionState, accentColor, l10n),
      ],
    );
  }

  Widget _buildTabBar(Color accentColor, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('All', l10n.all)),
          Expanded(child: _buildTabButton('Expense', l10n.expense)),
          Expanded(child: _buildTabButton('Income', l10n.income)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        final filterType = type == 'All' 
            ? null 
            : type.toLowerCase();
        ref.read(transactionProvider.notifier).setTypeFilter(filterType);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionState state, Color accentColor, AppLocalizations l10n) {
    if (state.isLoading && state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            l10n.noTransactions,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final displayTransactions = state.transactions.take(5).toList();

    return Column(
      children: [
        ...displayTransactions.map((transaction) {
          return TransactionItem(
            transaction: transaction,
            onTap: () {},
          );
        }),
        if (state.transactions.length > 5)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionsScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: accentColor),
            child: Text(l10n.seeAllTransactions),
          ),
      ],
    );
  }
}

