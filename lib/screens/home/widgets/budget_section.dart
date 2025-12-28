import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/budget_provider.dart';
import '../../../utils/currency_formatter.dart';
import '../../budgets/budget_form_screen.dart';

class BudgetSection extends ConsumerWidget {
  const BudgetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final activeBudgets = budgetState.activeBudgets;

    if (activeBudgets.isEmpty) {
      return _buildCreateBudgetPrompt(context, ref);
    }

    return _buildActiveBudget(context, ref, activeBudgets);
  }

  Widget _buildCreateBudgetPrompt(BuildContext context, WidgetRef ref) {
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
          color: const Color(0xFFE8EBFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EBFA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7FD7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline,
                color: Color(0xFF6B7FD7),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set up a budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Track your spending habits',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: Color(0xFF6B7FD7)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBudget(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithSpent> activeBudgets,
  ) {
    final budgetData = activeBudgets.first;
    final budget = budgetData.budget;
    final startDate = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final now = DateTime.now();

    final totalDays = endDate.difference(startDate).inDays;
    final daysPassed = now.difference(startDate).inDays;
    final timelineProgress = totalDays > 0
        ? (daysPassed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetFormScreen(budget: budget),
          ),
        ).then((_) => ref.read(budgetProvider.notifier).loadBudgets());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE8EBFA),
              const Color(0xFFE8EBFA).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(budget.name),
            const SizedBox(height: 12),
            _buildBalanceDisplay(budgetData),
            const SizedBox(height: 16),
            _buildTimeline(context, startDate, endDate, timelineProgress),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getBudgetStatusText(budgetData),
                style: TextStyle(
                  fontSize: 12,
                  color: budgetData.isOverBudget
                      ? Colors.red.shade700
                      : Colors.black54,
                ),
              ),
            ),
            if (activeBudgets.length > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '+${activeBudgets.length - 1} more budget${activeBudgets.length > 2 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7FD7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
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
            color: const Color(0xFF6B7FD7).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history,
            size: 20,
            color: Color(0xFF6B7FD7),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(BudgetWithSpent budgetData) {
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
            text: ' left of ${CurrencyFormatter.format(budgetData.budget.limitAmount)}',
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
          left: 50 +
              (MediaQuery.of(context).size.width - 130) * timelineProgress -
              20,
          top: -20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7FD7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(width: 2, height: 20, color: const Color(0xFF6B7FD7)),
            ],
          ),
        ),
      ],
    );
  }

  String _getBudgetStatusText(BudgetWithSpent budgetData) {
    if (budgetData.isOverBudget) {
      return 'Over budget by ${CurrencyFormatter.format(budgetData.spent - budgetData.budget.limitAmount)}';
    }
    if (budgetData.daysRemaining == 0) {
      return 'Budget period ended';
    }
    return 'You can spend ${CurrencyFormatter.format(budgetData.dailyAllowance)}/day for ${budgetData.daysRemaining} more days';
  }
}

