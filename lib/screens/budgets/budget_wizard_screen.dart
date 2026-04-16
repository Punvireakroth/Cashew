import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../providers/budget_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/database_service.dart';
import '../../utils/budget_rule_categories.dart';
import '../../utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';

class BudgetWizardScreen extends ConsumerStatefulWidget {
  const BudgetWizardScreen({super.key});

  @override
  ConsumerState<BudgetWizardScreen> createState() => _BudgetWizardScreenState();
}

class _BudgetWizardScreenState extends ConsumerState<BudgetWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _db = DatabaseService();

  // Step 1: Setup
  String? _selectedAccountId;
  late DateTime _startDate;
  late DateTime _endDate;

  // Step 3: Category assignments
  Set<String> _needsCategoryIds = {};
  Set<String> _wantsCategoryIds = {};
  Set<String> _savingsCategoryIds = {};

  List<Category> _availableCategories = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  // Computed amounts
  double get _totalAmount =>
      double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^\d.]'), ''),
      ) ??
      0;
  double get _needsAmount => _totalAmount * BudgetRulePercentages.needs;
  double get _wantsAmount => _totalAmount * BudgetRulePercentages.wants;
  double get _savingsAmount => _totalAmount * BudgetRulePercentages.savings;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _db.getUnassignedExpenseCategories();
      final categorized = BudgetRuleCategorizer.categorizeExpenses(categories);

      setState(() {
        _availableCategories = categories;
        _needsCategoryIds = categorized[BudgetRuleType.needs]!
            .map((c) => c.id)
            .toSet();
        _wantsCategoryIds = categorized[BudgetRuleType.wants]!
            .map((c) => c.id)
            .toSet();
        _savingsCategoryIds = categorized[BudgetRuleType.savings]!
            .map((c) => c.id)
            .toSet();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (_totalAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }
    }

    if (_currentStep == 2) {
      // Validate at least one category per budget
      if (_needsCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one Needs category'),
          ),
        );
        return;
      }
      if (_wantsCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one Wants category'),
          ),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitWizard();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitWizard() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await ref
          .read(budgetProvider.notifier)
          .createBudgetsFromRule(
            accountId: _selectedAccountId,
            totalAmount: _totalAmount,
            startDate: _startDate.millisecondsSinceEpoch,
            endDate: _endDate.millisecondsSinceEpoch,
            needsCategoryIds: _needsCategoryIds.toList(),
            wantsCategoryIds: _wantsCategoryIds.toList(),
            savingsCategoryIds: _savingsCategoryIds.toList(),
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('50/30/20 budgets created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        final error = ref.read(budgetProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to create budgets'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleCategory(
    String categoryId,
    BudgetRuleType fromType,
    BudgetRuleType toType,
  ) {
    setState(() {
      // Remove from current type
      switch (fromType) {
        case BudgetRuleType.needs:
          _needsCategoryIds.remove(categoryId);
          break;
        case BudgetRuleType.wants:
          _wantsCategoryIds.remove(categoryId);
          break;
        case BudgetRuleType.savings:
          _savingsCategoryIds.remove(categoryId);
          break;
      }

      // Add to new type
      switch (toType) {
        case BudgetRuleType.needs:
          _needsCategoryIds.add(categoryId);
          break;
        case BudgetRuleType.wants:
          _wantsCategoryIds.add(categoryId);
          break;
        case BudgetRuleType.savings:
          _savingsCategoryIds.add(categoryId);
          break;
      }
    });
  }

  void _removeCategory(String categoryId, BudgetRuleType type) {
    setState(() {
      switch (type) {
        case BudgetRuleType.needs:
          _needsCategoryIds.remove(categoryId);
          break;
        case BudgetRuleType.wants:
          _wantsCategoryIds.remove(categoryId);
          break;
        case BudgetRuleType.savings:
          _savingsCategoryIds.remove(categoryId);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: Text(
          l10n.budgetWizardTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              type: StepperType.vertical,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : details.onStepContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7FD7),
                        ),
                        child: _isSubmitting && _currentStep == 3
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentStep == 3
                                    ? l10n.createBudgets
                                    : l10n.continueText,
                              ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(
                          _currentStep == 0 ? l10n.cancel : l10n.back,
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Setup
                Step(
                  title: Text(l10n.wizardStep1Title),
                  subtitle: Text(l10n.wizardStep1Subtitle),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildStep1Setup(accountState.accounts, l10n),
                ),
                // Step 2: Preview Split
                Step(
                  title: Text(l10n.wizardStep2Title),
                  subtitle: Text(l10n.wizardStep2Subtitle),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildStep2Preview(l10n),
                ),
                // Step 3: Categories
                Step(
                  title: Text(l10n.wizardStep3Title),
                  subtitle: Text(l10n.wizardStep3Subtitle),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildStep3Categories(l10n),
                ),
                // Step 4: Confirm
                Step(
                  title: Text(l10n.wizardStep4Title),
                  subtitle: Text(l10n.wizardStep4Subtitle),
                  isActive: _currentStep >= 3,
                  state: StepState.indexed,
                  content: _buildStep4Confirm(l10n),
                ),
              ],
            ),
    );
  }

  Widget _buildStep1Setup(List<Account> accounts, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Amount
          Text(
            l10n.totalMonthlyBudget,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseEnterAmount;
              }
              final amount = double.tryParse(
                value.replaceAll(RegExp(r'[^\d.]'), ''),
              );
              if (amount == null || amount <= 0) {
                return l10n.pleaseEnterValidAmount;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Account Selection
          Text(
            l10n.trackAccount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedAccountId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                hint: Text(l10n.allAccounts),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF6B7FD7),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.allAccounts),
                      ],
                    ),
                  ),
                  ...accounts.map(
                    (account) => DropdownMenuItem<String?>(
                      value: account.id,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            color: Color(0xFF6B7FD7),
                          ),
                          const SizedBox(width: 12),
                          Text(account.name),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedAccountId = value),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Period Selection
          Text(
            l10n.budgetPeriod,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildPeriodChip(l10n.thisMonth, 'this_month'),
              _buildPeriodChip(l10n.nextMonth, 'next_month'),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateRange(),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _isSelectedPeriod(period);
    return GestureDetector(
      onTap: () => _setQuickPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B7FD7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B7FD7) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _isSelectedPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'this_month':
        return _startDate.year == now.year &&
            _startDate.month == now.month &&
            _startDate.day == 1;
      case 'next_month':
        return _startDate.year == now.year &&
            _startDate.month == now.month + 1 &&
            _startDate.day == 1;
      default:
        return false;
    }
  }

  void _setQuickPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      switch (period) {
        case 'this_month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'next_month':
          _startDate = DateTime(now.year, now.month + 1, 1);
          _endDate = DateTime(now.year, now.month + 2, 0);
          break;
      }
    });
  }

  Widget _buildDateRange() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6B7FD7)),
          const SizedBox(width: 12),
          Text(
            '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7FD7),
            ),
          ),
          const Spacer(),
          Text(
            '${_endDate.difference(_startDate).inDays + 1} days',
            style: const TextStyle(color: Color(0xFF6B7FD7)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Preview(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rule explanation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBFA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF6B7FD7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.budgetRuleExplanation,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Split preview
        _buildSplitCard(
          l10n.needs,
          '50%',
          _needsAmount,
          const Color(0xFF2196F3),
          Icons.home,
          l10n.needsDescription,
        ),
        const SizedBox(height: 12),
        _buildSplitCard(
          l10n.wants,
          '30%',
          _wantsAmount,
          const Color(0xFF9C27B0),
          Icons.shopping_bag,
          l10n.wantsDescription,
        ),
        const SizedBox(height: 12),
        _buildSplitCard(
          l10n.savings,
          '20%',
          _savingsAmount,
          const Color(0xFF4CAF50),
          Icons.savings,
          l10n.savingsDescription,
        ),

        const SizedBox(height: 24),

        // Total summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.total,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.format(_totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7FD7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitCard(
    String title,
    String percentage,
    double amount,
    Color color,
    IconData icon,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        percentage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Categories(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assignCategoriesHint,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Needs Categories
        _buildCategorySection(
          l10n.needs,
          '50%',
          const Color(0xFF2196F3),
          BudgetRuleType.needs,
          _needsCategoryIds,
        ),
        const SizedBox(height: 16),

        // Wants Categories
        _buildCategorySection(
          l10n.wants,
          '30%',
          const Color(0xFF9C27B0),
          BudgetRuleType.wants,
          _wantsCategoryIds,
        ),
        const SizedBox(height: 16),

        // Savings Categories
        _buildCategorySection(
          l10n.savings,
          '20%',
          const Color(0xFF4CAF50),
          BudgetRuleType.savings,
          _savingsCategoryIds,
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    String percentage,
    Color color,
    BudgetRuleType type,
    Set<String> selectedIds,
  ) {
    final categories = _availableCategories
        .where((c) => selectedIds.contains(c.id))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$title ($percentage)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${categories.length} categories',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Category chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: categories.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No categories assigned',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return _buildCategoryChip(category, type, color);
                    }).toList(),
                  ),
          ),
          // Add category button
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: _buildAddCategoryButton(type, color),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    Category category,
    BudgetRuleType type,
    Color sectionColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(category.color).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(category.color).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category.iconName),
            size: 16,
            color: Color(category.color),
          ),
          const SizedBox(width: 6),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(category.color),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showMoveDialog(category, type),
            child: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton(BudgetRuleType type, Color color) {
    // Get unassigned categories
    final assignedIds = {
      ..._needsCategoryIds,
      ..._wantsCategoryIds,
      ..._savingsCategoryIds,
    };
    final unassigned = _availableCategories
        .where((c) => !assignedIds.contains(c.id))
        .toList();

    if (unassigned.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showAddCategoryDialog(type, color, unassigned),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              'Add category',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
    BudgetRuleType type,
    Color color,
    List<Category> unassigned,
  ) {
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
                'Add to ${BudgetRuleCategorizer.getDisplayName(type)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: unassigned.length,
                itemBuilder: (context, index) {
                  final category = unassigned[index];
                  return ListTile(
                    leading: Icon(
                      _getCategoryIcon(category.iconName),
                      color: Color(category.color),
                    ),
                    title: Text(category.name),
                    onTap: () {
                      setState(() {
                        switch (type) {
                          case BudgetRuleType.needs:
                            _needsCategoryIds.add(category.id);
                            break;
                          case BudgetRuleType.wants:
                            _wantsCategoryIds.add(category.id);
                            break;
                          case BudgetRuleType.savings:
                            _savingsCategoryIds.add(category.id);
                            break;
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(Category category, BudgetRuleType currentType) {
    final l10n = AppLocalizations.of(context)!;
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
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Move options
            if (currentType != BudgetRuleType.needs)
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFF2196F3)),
                title: Text('${l10n.moveTo} ${l10n.needs}'),
                onTap: () {
                  _toggleCategory(
                    category.id,
                    currentType,
                    BudgetRuleType.needs,
                  );
                  Navigator.pop(context);
                },
              ),
            if (currentType != BudgetRuleType.wants)
              ListTile(
                leading: const Icon(
                  Icons.shopping_bag,
                  color: Color(0xFF9C27B0),
                ),
                title: Text('${l10n.moveTo} ${l10n.wants}'),
                onTap: () {
                  _toggleCategory(
                    category.id,
                    currentType,
                    BudgetRuleType.wants,
                  );
                  Navigator.pop(context);
                },
              ),
            if (currentType != BudgetRuleType.savings)
              ListTile(
                leading: const Icon(Icons.savings, color: Color(0xFF4CAF50)),
                title: Text('${l10n.moveTo} ${l10n.savings}'),
                onTap: () {
                  _toggleCategory(
                    category.id,
                    currentType,
                    BudgetRuleType.savings,
                  );
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.remove_circle_outline,
                color: Colors.red.shade400,
              ),
              title: Text(
                l10n.removeFromBudget,
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () {
                _removeCategory(category.id, currentType);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Confirm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reviewBudgetsSummary,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Needs Budget Summary
        _buildBudgetSummaryCard(
          l10n.needsBudget,
          _needsAmount,
          _needsCategoryIds.length,
          const Color(0xFF2196F3),
          Icons.home,
        ),
        const SizedBox(height: 12),

        // Wants Budget Summary
        _buildBudgetSummaryCard(
          l10n.wantsBudget,
          _wantsAmount,
          _wantsCategoryIds.length,
          const Color(0xFF9C27B0),
          Icons.shopping_bag,
        ),
        const SizedBox(height: 12),

        // Savings Budget Summary
        if (_savingsCategoryIds.isNotEmpty)
          _buildBudgetSummaryCard(
            l10n.savingsBudget,
            _savingsAmount,
            _savingsCategoryIds.length,
            const Color(0xFF4CAF50),
            Icons.savings,
          ),

        const SizedBox(height: 24),

        // Period info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBFA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFF6B7FD7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.budgetPeriod,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('MMMM d').format(_startDate)} - ${DateFormat('MMMM d, yyyy').format(_endDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7FD7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSummaryCard(
    String title,
    double amount,
    int categoryCount,
    Color color,
    IconData icon,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.categoryCount(categoryCount),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    const iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'local_hospital': Icons.local_hospital,
      'medical_services': Icons.medical_services,
      'school': Icons.school,
      'movie': Icons.movie,
      'flight': Icons.flight,
      'sports_esports': Icons.sports_esports,
      'pets': Icons.pets,
      'card_giftcard': Icons.card_giftcard,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'trending_up': Icons.trending_up,
      'account_balance': Icons.account_balance,
      'savings': Icons.savings,
      'receipt_long': Icons.receipt_long,
      'spa': Icons.spa,
      'fitness_center': Icons.fitness_center,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
