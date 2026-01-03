import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/budget_card.dart';
import 'budget_form_screen.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetProvider.notifier).loadBudgets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _archiveBudget(BudgetWithSpent budgetData, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.archiveBudget),
        content: Text(l10n.archiveConfirmMessage(budgetData.budget.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.archive),
            ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(budgetProvider.notifier)
          .archiveBudget(budgetData.budget.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.budgetArchivedMessage(budgetData.budget.name)),
            action: SnackBarAction(
              label: l10n.restore,
              onPressed: () {
                ref
                    .read(budgetProvider.notifier)
                    .restoreBudget(budgetData.budget.id);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _restoreBudget(BudgetWithSpent budgetData, AppLocalizations l10n) async {
    final success = await ref
        .read(budgetProvider.notifier)
        .restoreBudget(budgetData.budget.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.budgetRestored(budgetData.budget.name))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final archivedCount = budgetState.archivedBudgets.length;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: Text(
          l10n.budgets,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: Colors.black54,
          indicatorColor: accentColor,
          tabs: [
            Tab(text: l10n.active),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.archived),
                  if (archivedCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$archivedCount',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Budgets Tab
          RefreshIndicator(
            onRefresh: () => ref.read(budgetProvider.notifier).loadBudgets(),
            color: accentColor,
            child: budgetState.isLoading && budgetState.budgets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : budgetState.budgets.isEmpty
                ? _buildEmptyState(accentColor, l10n)
                : _buildActiveBudgetList(budgetState, accentColor, l10n),
          ),
          // Archived Budgets Tab
          RefreshIndicator(
            onRefresh: () => ref.read(budgetProvider.notifier).loadBudgets(),
            color: accentColor,
            child: budgetState.archivedBudgets.isEmpty
                ? _buildEmptyArchivedState(l10n)
                : _buildArchivedBudgetList(budgetState, l10n),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBudget,
        backgroundColor: accentColor,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noBudgets,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createBudgetPrompt,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToAddBudget,
              icon: const Icon(Icons.add),
              label: Text(l10n.createBudget),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
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

  Widget _buildEmptyArchivedState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.archive_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noArchivedBudgets,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.archivedBudgetsHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBudgetList(BudgetState budgetState, Color accentColor, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Active budgets section
        if (budgetState.activeBudgets.isNotEmpty) ...[
          ...budgetState.activeBudgets.map((budgetData) {
            return _buildSwipeableBudgetCard(budgetData, isArchived: false, accentColor: accentColor, l10n: l10n);
          }),
        ],

        // Add budget card
        AddBudgetCard(onTap: _navigateToAddBudget),

        // Expired budgets section (prompt to renew or archive)
        if (budgetState.expiredBudgets.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader(
            l10n.expiredBudgets,
            subtitle: l10n.renewOrArchiveBudgets,
            icon: Icons.timer_off_outlined,
            color: Colors.orange,
          ),
          ...budgetState.expiredBudgets.map((budgetData) {
            return _buildExpiredBudgetCard(budgetData, accentColor, l10n);
          }),
        ],

        // Future budgets section
        if (budgetState.futureBudgets.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader(
            l10n.upcomingBudgets,
            icon: Icons.schedule,
            color: accentColor,
          ),
          ...budgetState.futureBudgets.map((budgetData) {
            return Opacity(
              opacity: 0.8,
              child: _buildSwipeableBudgetCard(budgetData, isArchived: false, accentColor: accentColor, l10n: l10n),
            );
          }),
        ],

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildArchivedBudgetList(BudgetState budgetState, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...budgetState.archivedBudgets.map((budgetData) {
          return _buildSwipeableBudgetCard(budgetData, isArchived: true, l10n: l10n);
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? subtitle,
    IconData? icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? Colors.black54),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black54,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableBudgetCard(
    BudgetWithSpent budgetData, {
    required bool isArchived,
    Color? accentColor,
    AppLocalizations? l10n,
  }) {
    final localizations = l10n ?? AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(budgetData.budget.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (isArchived) {
          await _restoreBudget(budgetData, localizations);
        } else {
          await _archiveBudget(budgetData, localizations);
        }
        return false; // Don't actually dismiss, we handle it manually
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isArchived ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isArchived ? Icons.unarchive : Icons.archive,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isArchived ? localizations.restore : localizations.archive,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Opacity(
        opacity: isArchived ? 0.7 : 1.0,
        child: BudgetCard(
          budgetData: budgetData,
          accentColor: accentColor,
          onTap: () => _navigateToEditBudget(budgetData),
          onHistoryTap: isArchived
              ? null
              : () => _showBudgetOptions(budgetData, localizations),
        ),
      ),
    );
  }

  Widget _buildExpiredBudgetCard(BudgetWithSpent budgetData, Color accentColor, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade300, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: 0.8,
            child: BudgetCard(
              budgetData: budgetData,
              accentColor: accentColor,
              onTap: () => _navigateToEditBudget(budgetData),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _archiveBudget(budgetData, l10n),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: Text(l10n.archive),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showRenewalDialog(budgetData, l10n),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.renew),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetOptions(BudgetWithSpent budgetData, AppLocalizations l10n) {
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
              child: Text(
                budgetData.budget.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editBudget),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditBudget(budgetData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l10n.archiveBudget),
              onTap: () {
                Navigator.pop(context);
                _archiveBudget(budgetData, l10n);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(
                l10n.deleteBudget,
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(budgetData, l10n);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BudgetWithSpent budgetData, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBudget),
        content: Text(l10n.deleteConfirmMessage(budgetData.budget.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(budgetProvider.notifier)
                  .deleteBudget(budgetData.budget.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showRenewalDialog(BudgetWithSpent budgetData, AppLocalizations l10n) {
    final now = DateTime.now();
    // Calculate next period based on the original budget duration
    final originalDuration =
        budgetData.budget.endDate - budgetData.budget.startDate;
    final newStartDate = DateTime(now.year, now.month, 1);
    final newEndDate = newStartDate.add(
      Duration(milliseconds: originalDuration),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renewBudget),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.renewBudgetPrompt(budgetData.budget.name)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBFA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.newPeriod}:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${_formatDate(newStartDate)} - ${_formatDate(newEndDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.limit}: \$${budgetData.budget.limitAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    l10n.categoryCount(budgetData.categoryIds.length),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(budgetProvider.notifier)
                  .renewBudget(
                    budgetData,
                    newStartDate: newStartDate.millisecondsSinceEpoch,
                    newEndDate: newEndDate.millisecondsSinceEpoch,
                  );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.budgetRenewedSuccess)),
                );
              }
            },
            child: Text(l10n.renew),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
