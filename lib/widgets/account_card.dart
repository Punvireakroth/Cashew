import 'package:flutter/material.dart';
import '../models/account.dart';
import '../utils/currency_formatter.dart';

/// A reusable card widget for displaying account information
/// Styled to match Cashew app design
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int transactionCount;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onLongPress,
    this.transactionCount = 0,
  });

  /// Get color based on account hash for visual distinction
  Color _getAccountColor() {
    final colors = [
      const Color(0xFF6B7FD7), // Purple
      const Color(0xFF7BD389), // Green
      const Color(0xFFEF9A9A), // Pink
      const Color(0xFF81C9FA), // Blue
      const Color(0xFFFFC270), // Orange
      const Color(0xFFB39DDB), // Lavender
    ];
    return colors[account.id.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _getAccountColor().withOpacity(0.3),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colored dot indicator
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getAccountColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // Account name
                Text(
                  account.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Balance
                Text(
                  CurrencyFormatter.format(
                    account.balance,
                    currency: account.currency,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Transaction count
                Text(
                  transactionCount == 1
                      ? '1 transaction'
                      : '$transactionCount transactions',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical account card for list view (used in accounts screen)
class AccountCardVertical extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;
  final int transactionCount;

  const AccountCardVertical({
    super.key,
    required this.account,
    this.onTap,
    this.transactionCount = 0,
  });

  /// Get color based on account hash
  Color _getAccountColor() {
    final colors = [
      const Color(0xFF6B7FD7),
      const Color(0xFF7BD389),
      const Color(0xFFEF9A9A),
      const Color(0xFF81C9FA),
      const Color(0xFFFFC270),
      const Color(0xFFB39DDB),
    ];
    return colors[account.id.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _getAccountColor().withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Colored dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getAccountColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),

              // Account details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transactionCount == 1
                          ? '1 transaction'
                          : '$transactionCount transactions',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(
                      account.balance,
                      currency: account.currency,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.currency,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
