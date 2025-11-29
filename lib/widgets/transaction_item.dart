import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionItem({
    Key? key,
    required this.transaction,
    this.onTap,
    this.showDate = false,
  }) : super(key: key);

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
    final hasNotes = transaction.notes != null && transaction.notes!.isNotEmpty;

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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category Icon
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(category.color).withValues(alpha: 0.15),
                child: Icon(
                  _getIconData(category.iconName),
                  color: Color(category.color),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Notes indicator
              if (hasNotes) ...[
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
              ],
              // Amount
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncome ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: amountColor,
                    size: 20,
                  ),
                  Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      'wifi': Icons.wifi,
      'egg': Icons.egg_alt,
      'train': Icons.train,
      'balance': Icons.account_balance_wallet,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}
