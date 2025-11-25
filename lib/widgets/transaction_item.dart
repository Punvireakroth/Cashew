import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionItem({Key? key, required this.transaction, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoryProvider);
    final category = categoryState.categories
        .where((cat) => cat.id == transaction.categoryId)
        .firstOrNull;

    if (category == null) {
      return const SizedBox.shrink();
    }

    final isIncome = category.isIncome;
    final amountColor = isIncome ? Colors.green : Colors.red[700];
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) =>
                _showDeleteConfirmation(context, ref, category),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Color(category.color).withValues(alpha: 0.2),
          child: Icon(
            _getIconData(category.iconName),
            color: Color(category.color),
            size: 24,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              category.name,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d, yyyy').format(date),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await ref
                  .read(transactionProvider.notifier)
                  .deleteTransaction(transaction, category);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final error = ref.read(transactionProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to delete transaction'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Material Icons
    final iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart,
      'local_gas_station': Icons.local_gas_station,
      'home': Icons.home,
      'medical_services': Icons.medical_services,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'flight': Icons.flight,
      'directions_car': Icons.directions_car,
      'phone_android': Icons.phone_android,
      'clothing': Icons.checkroom,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'card_giftcard': Icons.card_giftcard,
      'other': Icons.more_horiz,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'business': Icons.business,
      'trending_up': Icons.trending_up,
      'savings': Icons.savings,
      'account_balance': Icons.account_balance,
      'credit_card': Icons.credit_card,
      'receipt': Icons.receipt,
      'payment': Icons.payment,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'fastfood': Icons.fastfood,
      'local_pizza': Icons.local_pizza,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}
