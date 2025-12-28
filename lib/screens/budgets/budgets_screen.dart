import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/budget_card.dart';
import 'budget_form_screen.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetProvider.notifier).loadBudgets();
    });
  }

  void _navigateToAddBudget() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const BudgetFormScreen()),
    );
    if (result == true) {
      ref.read(budgetProvider.notifier).loadBudgets();
    }
  }

  void _navigateToEditBudget(BudgetWithSpent budgetData) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetFormScreen(
          budget: budgetData.budget,
          existingCategoryIds: budgetData.categoryIds,
        ),
      ),
    );
    if (result == true) {
      ref.read(budgetProvider.notifier).loadBudgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: const Text(
          'Budgets',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
            onPressed: () {
              // Could open a reorder/manage mode in the future
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetProvider.notifier).loadBudgets(),
        color: const Color(0xFF6B7FD7),
        child: budgetState.isLoading && budgetState.budgets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : budgetState.budgets.isEmpty
            ? _buildEmptyState()
            : _buildBudgetList(budgetState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBudget,
        backgroundColor: const Color(0xFF6B7FD7),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBFA).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No budgets yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start tracking\nyour spending habits',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToAddBudget,
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B7FD7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(BudgetState budgetState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Active budgets section
        ...budgetState.activeBudgets.map((budgetData) {
          return BudgetCard(
            budgetData: budgetData,
            onTap: () => _navigateToEditBudget(budgetData),
            onHistoryTap: () => _showBudgetHistory(budgetData),
          );
        }),

        // Add budget card
        AddBudgetCard(onTap: _navigateToAddBudget),

        // Past/Future budgets section (if any)
        if (_getPastBudgets(budgetState).isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Past Budgets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          ..._getPastBudgets(budgetState).map((budgetData) {
            return Opacity(
              opacity: 0.6,
              child: BudgetCard(
                budgetData: budgetData,
                onTap: () => _navigateToEditBudget(budgetData),
              ),
            );
          }),
        ],

        // Future budgets section
        if (_getFutureBudgets(budgetState).isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Upcoming Budgets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          ..._getFutureBudgets(budgetState).map((budgetData) {
            return Opacity(
              opacity: 0.8,
              child: BudgetCard(
                budgetData: budgetData,
                onTap: () => _navigateToEditBudget(budgetData),
              ),
            );
          }),
        ],

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  List<BudgetWithSpent> _getPastBudgets(BudgetState state) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return state.budgets.where((b) => b.budget.endDate < now).toList();
  }

  List<BudgetWithSpent> _getFutureBudgets(BudgetState state) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return state.budgets.where((b) => b.budget.startDate > now).toList();
  }

  void _showBudgetHistory(BudgetWithSpent budgetData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
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
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Color(0xFF6B7FD7)),
                      const SizedBox(width: 12),
                      Text(
                        '${budgetData.budget.name} History',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Budget history coming soon',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
