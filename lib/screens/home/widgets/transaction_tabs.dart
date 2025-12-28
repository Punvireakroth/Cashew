import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/transaction_provider.dart';
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

    return Column(
      children: [
        _buildTabBar(),
        const SizedBox(height: 16),
        _buildTransactionList(transactionState),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('All')),
          Expanded(child: _buildTabButton('Expense')),
          Expanded(child: _buildTabButton('Income')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = label);
        final filterType = label == 'All' 
            ? null 
            : label.toLowerCase();
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

  Widget _buildTransactionList(TransactionState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.black54),
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
            child: const Text('See all transactions'),
          ),
      ],
    );
  }
}

