import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../providers/budget_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  final Budget? budget;
  final List<String>? existingCategoryIds;

  const BudgetFormScreen({super.key, this.budget, this.existingCategoryIds});

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _db = DatabaseService();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;

  // Account selection: null means "All Accounts"
  String? _selectedAccountId;

  // Category selection
  Set<String> _selectedCategoryIds = {};
  List<Category> _availableCategories = [];
  bool _isCategoriesLoading = true;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.budget!.name;
      _limitController.text = widget.budget!.limitAmount.toStringAsFixed(0);
      _startDate = DateTime.fromMillisecondsSinceEpoch(
        widget.budget!.startDate,
      );
      _endDate = DateTime.fromMillisecondsSinceEpoch(widget.budget!.endDate);
      _selectedAccountId = widget.budget!.accountId;

      // Load existing category IDs
      if (widget.existingCategoryIds != null) {
        _selectedCategoryIds = Set.from(widget.existingCategoryIds!);
      }
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    }

    _loadAvailableCategories();
  }

  Future<void> _loadAvailableCategories() async {
    setState(() => _isCategoriesLoading = true);

    try {
      final categories = await _db.getUnassignedExpenseCategories(
        excludeBudgetId: _isEditing ? widget.budget!.id : null,
      );
      setState(() {
        _availableCategories = categories;
        _isCategoriesLoading = false;
      });
    } catch (e) {
      setState(() => _isCategoriesLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF6B7FD7)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF6B7FD7)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endDate = picked);
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
        case 'this_week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = _startDate.add(const Duration(days: 6));
          break;
        case 'next_week':
          _startDate = now.add(Duration(days: 8 - now.weekday));
          _endDate = _startDate.add(const Duration(days: 6));
          break;
      }
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate categories
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final limitAmount = double.parse(
        _limitController.text.replaceAll(RegExp(r'[^\d.]'), ''),
      );

      final budget = Budget(
        id: _isEditing ? widget.budget!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        accountId: _selectedAccountId,
        limitAmount: limitAmount,
        startDate: _startDate.millisecondsSinceEpoch,
        endDate: _endDate.millisecondsSinceEpoch,
        createdAt: _isEditing ? widget.budget!.createdAt : now,
        updatedAt: now,
      );

      bool success;
      if (_isEditing) {
        success = await ref
            .read(budgetProvider.notifier)
            .updateBudget(budget, _selectedCategoryIds.toList());
      } else {
        success = await ref
            .read(budgetProvider.notifier)
            .createBudget(budget, _selectedCategoryIds.toList());
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Budget updated successfully!'
                  : 'Budget created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        final error = ref.read(budgetProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save budget'),
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Budget' : 'New Budget',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.archive_outlined, color: Color(0xFF6B7FD7)),
              onPressed: _showArchiveConfirmation,
              tooltip: 'Archive',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Budget Name
            _buildSectionTitle('Budget Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g., Monthly Groceries, Entertainment',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a budget name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Budget Limit
            _buildSectionTitle('Budget Limit'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a budget limit';
                }
                final amount = double.tryParse(
                  value.replaceAll(RegExp(r'[^\d.]'), ''),
                );
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Account Selection
            _buildSectionTitle('Track Account'),
            const SizedBox(height: 8),
            _buildAccountSelector(accountState.accounts),
            const SizedBox(height: 24),

            // Category Selection
            _buildSectionTitle('Categories to Track'),
            const SizedBox(height: 4),
            Text(
              'Select expense categories for this budget',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Budget Period
            _buildSectionTitle('Budget Period'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickPeriodChip('This Month', 'this_month'),
                _buildQuickPeriodChip('Next Month', 'next_month'),
                _buildQuickPeriodChip('This Week', 'this_week'),
                _buildQuickPeriodChip('Next Week', 'next_week'),
              ],
            ),
            const SizedBox(height: 16),

            // Custom date selection
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: _selectStartDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    label: 'End Date',
                    date: _endDate,
                    onTap: _selectEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Period summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Color(0xFF6B7FD7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_endDate.difference(_startDate).inDays + 1} days',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7FD7),
                    ),
                  ),
                  const Spacer(),
                  if (_limitController.text.isNotEmpty)
                    Text(
                      '${CurrencyFormatter.format((double.tryParse(_limitController.text) ?? 0) / (_endDate.difference(_startDate).inDays + 1))}/day',
                      style: const TextStyle(color: Color(0xFF6B7FD7)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FD7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Budget' : 'Create Budget',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildAccountSelector(List<Account> accounts) {
    return Container(
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
          hint: const Text('All Accounts'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Color(0xFF6B7FD7)),
                  SizedBox(width: 12),
                  Text('All Accounts'),
                ],
              ),
            ),
            ...accounts.map(
              (account) => DropdownMenuItem<String?>(
                value: account.id,
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFF6B7FD7)),
                    const SizedBox(width: 12),
                    Text(account.name),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedAccountId = value);
          },
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_isCategoriesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All expense categories are already assigned to other budgets.',
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableCategories.map((category) {
        final isSelected = _selectedCategoryIds.contains(category.id);
        return GestureDetector(
          onTap: () => _toggleCategory(category.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Color(category.color) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Color(category.color)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(category.color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category.iconName),
                  size: 18,
                  color: isSelected ? Colors.white : Color(category.color),
                ),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    const iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'local_hospital': Icons.local_hospital,
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
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Widget _buildQuickPeriodChip(String label, String period) {
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
            _startDate.day == 1 &&
            _endDate.day == DateTime(now.year, now.month + 1, 0).day;
      case 'next_month':
        return _startDate.year == now.year &&
            _startDate.month == now.month + 1 &&
            _startDate.day == 1;
      default:
        return false;
    }
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF6B7FD7),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Budget'),
        content: Text(
          'Archive "${widget.budget!.name}"? You can restore it later from the Archived tab.',
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
                  .read(budgetProvider.notifier)
                  .archiveBudget(widget.budget!.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget archived'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B7FD7),
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete "${widget.budget!.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(budgetProvider.notifier)
                  .deleteBudget(widget.budget!.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
