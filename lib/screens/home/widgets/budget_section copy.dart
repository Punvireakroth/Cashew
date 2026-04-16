import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';
import '../../budgets/budget_form_screen.dart';

class BudgetSection extends ConsumerWidget {
  const BudgetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final l10n = AppLocalizations.of(context)!;
    final activeBudgets = budgetState.activeBudgets;
    final expiredBudgets = budgetState.expiredBudgets;

    return Column(
      children: [
        // Show expired budget banner if any
        if (expiredBudgets.isNotEmpty)
          _buildExpiredBudgetBanner(
            context,
            ref,
            expiredBudgets,
            accentColor,
            l10n,
          ),

        // Show active budget or create prompt
        if (activeBudgets.isEmpty)
          _buildCreateBudgetPrompt(context, ref, accentColor, l10n)
        else
          _buildActiveBudget(context, ref, activeBudgets, accentColor, l10n),
      ],
    );
  }

  Widget _buildExpiredBudgetBanner(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithSpent> expiredBudgets,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    final firstExpired = expiredBudgets.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_off_outlined,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expiredBudgets.length == 1
                      ? l10n.budgetExpired(firstExpired.budget.name)
                      : l10n.budgetsExpired(expiredBudgets.length),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.renewOrArchive,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showRenewalBottomSheet(
              context,
              ref,
              firstExpired,
              accentColor,
              l10n,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(l10n.action),
          ),
        ],
      ),
    );
  }

  void _showRenewalBottomSheet(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSpent budgetData,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final originalDuration =
        budgetData.budget.endDate - budgetData.budget.startDate;
    final newStartDate = DateTime(now.year, now.month, 1);
    final newEndDate = newStartDate.add(
      Duration(milliseconds: originalDuration),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_off_outlined,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '"${budgetData.budget.name}" ${l10n.expired}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryRow(
                          l10n.spent,
                          CurrencyFormatter.format(budgetData.spent),
                          budgetData.isOverBudget ? Colors.red : Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          l10n.budget,
                          CurrencyFormatter.format(
                            budgetData.budget.limitAmount,
                          ),
                          null,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          budgetData.isOverBudget ? l10n.overBy : l10n.saved,
                          CurrencyFormatter.format(
                            budgetData.isOverBudget
                                ? budgetData.spent -
                                      budgetData.budget.limitAmount
                                : budgetData.remaining,
                          ),
                          budgetData.isOverBudget ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref
                                .read(budgetProvider.notifier)
                                .archiveBudget(budgetData.budget.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.budgetArchived)),
                              );
                            }
                          },
                          icon: const Icon(Icons.archive_outlined, size: 18),
                          label: Text(l10n.archive),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await ref
                                .read(budgetProvider.notifier)
                                .renewBudget(
                                  budgetData,
                                  newStartDate:
                                      newStartDate.millisecondsSinceEpoch,
                                  newEndDate: newEndDate.millisecondsSinceEpoch,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.budgetRenewed)),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l10n.renew),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${l10n.newPeriod}: ${DateFormat('MMM d').format(newStartDate)} - ${DateFormat('MMM d').format(newEndDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateBudgetPrompt(
    BuildContext context,
    WidgetRef ref,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetFormScreen()),
        ).then((_) => ref.read(budgetProvider.notifier).loadBudgets());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pie_chart_outline, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.setUpBudget,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.trackSpendingHabits,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBudget(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithSpent> activeBudgets,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: activeBudgets.length,
        controller: PageController(viewportFraction: 1.0),
        itemBuilder: (context, index) {
          return _buildBudgetCard(
            context,
            ref,
            activeBudgets[index],
            accentColor,
            l10n,
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSpent budgetData,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    final budget = budgetData.budget;
    final startDate = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final now = DateTime.now();

    final totalDays = endDate.difference(startDate).inDays;
    final daysPassed = now.difference(startDate).inDays;
    final timelineProgress = totalDays > 0
        ? (daysPassed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetFormScreen(
                budget: budget,
                existingCategoryIds: budgetData.categoryIds,
              ),
            ),
          ).then((_) => ref.read(budgetProvider.notifier).loadBudgets());
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(budget.name, budgetData, accentColor, l10n),
              const SizedBox(height: 12),
              _buildBalanceDisplay(budgetData, l10n),
              const SizedBox(height: 16),
              _buildTimeline(
                context,
                startDate,
                endDate,
                timelineProgress,
                accentColor,
                l10n,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getBudgetStatusText(budgetData, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    color: budgetData.isOverBudget
                        ? Colors.red.shade700
                        : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String name,
    BudgetWithSpent budgetData,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    final accountText = budgetData.budget.tracksAllAccounts
        ? l10n.allAccounts
        : l10n.specificAccount;
    final categoryCount = budgetData.categoryIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 20, color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              budgetData.budget.tracksAllAccounts
                  ? Icons.account_balance_wallet
                  : Icons.account_balance,
              size: 12,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              accountText,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Icon(Icons.category_outlined, size: 12, color: accentColor),
            const SizedBox(width: 4),
            Text(
              l10n.categoryCount(categoryCount),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(
    BudgetWithSpent budgetData,
    AppLocalizations l10n,
  ) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: CurrencyFormatter.format(budgetData.remaining),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text:
                ' ${l10n.leftOf(CurrencyFormatter.format(budgetData.budget.limitAmount))}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    double timelineProgress,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Text(
              DateFormat('MMM d').format(startDate),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              DateFormat('MMM d').format(endDate),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        Positioned(
          left:
              50 +
              (MediaQuery.of(context).size.width - 130) * timelineProgress -
              20,
          top: -20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.today,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(width: 2, height: 20, color: accentColor),
            ],
          ),
        ),
      ],
    );
  }

  String _getBudgetStatusText(
    BudgetWithSpent budgetData,
    AppLocalizations l10n,
  ) {
    if (budgetData.isOverBudget) {
      return l10n.overBudgetBy(
        CurrencyFormatter.format(
          budgetData.spent - budgetData.budget.limitAmount,
        ),
      );
    }
    if (budgetData.daysRemaining == 0) {
      return l10n.budgetPeriodEnded;
    }
    return l10n.dailySpendingAllowance(
      CurrencyFormatter.format(budgetData.dailyAllowance),
      budgetData.daysRemaining,
    );
  }
}
