import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({Key? key, this.transaction}) : super(key: key);

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late TabController _tabController;

  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isExpense = true;
  bool _isLoading = false;

  Transaction? _oldTransaction;
  Category? _oldCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabController.index = _isExpense ? 0 : 1;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryProvider.notifier).loadCategories();
      await ref.read(accountProvider.notifier).loadAccounts();

      if (widget.transaction != null) {
        _populateForm();
      } else {
        final accounts = ref.read(accountProvider).accounts;
        if (accounts.isNotEmpty) {
          setState(() => _selectedAccountId = accounts.first.id);
        }
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _isExpense = _tabController.index == 0;
      _selectedCategoryId = null;
    });
  }

  void _populateForm() {
    final transaction = widget.transaction!;
    _oldTransaction = transaction;

    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toStringAsFixed(0);
    _notesController.text = transaction.notes ?? '';
    _selectedAccountId = transaction.accountId;
    _selectedCategoryId = transaction.categoryId;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(transaction.date);
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);

    final category = ref
        .read(categoryProvider.notifier)
        .getCategoryById(transaction.categoryId);
    if (category != null) {
      _oldCategory = category;
      setState(() {
        _isExpense = category.isExpense;
        _tabController.index = _isExpense ? 0 : 1;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final accountState = ref.watch(accountProvider);
    final theme = Theme.of(context);

    final categories = _isExpense
        ? categoryState.categories.where((cat) => cat.isExpense).toList()
        : categoryState.categories.where((cat) => cat.isIncome).toList();

    final accounts = accountState.accounts;
    final selectedCategory = _selectedCategoryId != null
        ? categories.where((c) => c.id == _selectedCategoryId).firstOrNull
        : null;

    final amount = double.tryParse(_amountController.text) ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Tab Bar
            _buildTabBar(theme),

            // Category Header Section
            _buildCategoryHeader(selectedCategory, amount, categories, theme),

            // Form Fields
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateTimeRow(theme),
                      const SizedBox(height: 20),
                      _buildAccountSelection(accounts, theme),
                      const SizedBox(height: 20),
                      _buildTitleField(theme),
                      const SizedBox(height: 16),
                      _buildNotesField(theme),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Button
            _buildBottomButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final expenseColor = Colors.red[700];
    final incomeColor = Colors.green[700];

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        labelColor: _isExpense ? expenseColor : incomeColor,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: _isExpense ? expenseColor : incomeColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_drop_down,
                  color: _tabController.index == 0
                      ? expenseColor
                      : Colors.grey[500],
                ),
                const Text('Expense'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_drop_up,
                  color: _tabController.index == 1
                      ? incomeColor
                      : Colors.grey[500],
                ),
                const Text('Income'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(
    Category? selectedCategory,
    double amount,
    List<Category> categories,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _showCategoryPicker(categories),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        color: Colors.grey[200],
        child: Row(
          children: [
            // Category Icon
            GestureDetector(
              onTap: () => _showCategoryPicker(categories),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: selectedCategory != null
                      ? Color(selectedCategory.color).withValues(alpha: 0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selectedCategory != null
                      ? _getIconData(selectedCategory.iconName)
                      : Icons.category,
                  size: 36,
                  color: selectedCategory != null
                      ? Color(selectedCategory.color)
                      : Colors.grey[600],
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _showAmountDialog,
                  child: Text(
                    '\$${amount.toStringAsFixed(amount == amount.toInt() ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCategory?.name ?? 'Select category',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(ThemeData theme) {
    final isToday = _isToday(_selectedDate);
    final isYesterday = _isYesterday(_selectedDate);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('MMM d, yyyy').format(_selectedDate);
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedTime.hour.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    ':',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedTime.minute.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedTime.period == DayPeriod.am ? 'AM' : 'PM',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelection(List accounts, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...accounts.map((account) {
          final isSelected = _selectedAccountId == account.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedAccountId = account.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                account.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          hintText: 'Title',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: Icon(Icons.text_fields, color: Colors.grey[400]),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Notes',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Icon(Icons.sticky_note_2_outlined, color: Colors.grey[400]),
          ),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.transaction == null
                        ? 'Add Transaction'
                        : 'Update Transaction',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showAmountDialog() {
    final controller = TextEditingController(text: _amountController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _amountController.text = controller.text);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryPickerSheet(
        categories: categories,
        selectedCategoryId: _selectedCategoryId,
        isExpense: _isExpense,
        onCategorySelected: (categoryId) {
          setState(() => _selectedCategoryId = categoryId);
        },
        onCategoryCreated: () {
          // Reload categories after creation
          ref.read(categoryProvider.notifier).loadCategories();
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if this transaction would exceed any active budget
  /// Returns true if user wants to continue, false to cancel
  Future<bool> _checkBudgetLimit(double amount) async {
    if (_selectedCategoryId == null || _selectedAccountId == null) return true;

    try {
      final db = DatabaseService();

      // Check if category is linked to an active budget
      final budget = await db.getActiveBudgetForCategory(
        _selectedCategoryId!,
        accountId: _selectedAccountId,
      );

      if (budget == null) return true;

      // Get category IDs for this budget
      final categoryIds = await db.getBudgetCategoryIds(budget.id);

      // Calculate current spending
      final spent = await db.getBudgetSpent(
        budget.startDate,
        budget.endDate,
        categoryIds,
        accountId: budget.accountId,
      );

      final remaining = budget.limitAmount - spent;

      // If transaction would exceed remaining budget, show warning
      if (amount > remaining) {
        final overBy = amount - remaining;

        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange.shade600,
            ),
            title: const Text('Budget Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This transaction will exceed your "${budget.name}" budget by ${CurrencyFormatter.format(overBy)}.',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildBudgetInfoRow(
                        'Budget Limit',
                        CurrencyFormatter.format(budget.limitAmount),
                      ),
                      const SizedBox(height: 8),
                      _buildBudgetInfoRow(
                        'Already Spent',
                        CurrencyFormatter.format(spent),
                      ),
                      const SizedBox(height: 8),
                      _buildBudgetInfoRow(
                        'Remaining',
                        remaining > 0
                            ? CurrencyFormatter.format(remaining)
                            : '\$0.00',
                        color: remaining > 0 ? Colors.green : Colors.red,
                      ),
                      const Divider(height: 16),
                      _buildBudgetInfoRow(
                        'This Transaction',
                        CurrencyFormatter.format(amount),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                ),
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
        );

        return confirmed ?? false;
      }

      // Show info if transaction uses most of remaining budget (>80%)
      if (remaining > 0 && amount > remaining * 0.8) {
        final percentUsed = ((spent + amount) / budget.limitAmount * 100)
            .toInt();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This will use $percentUsed% of your "${budget.name}" budget',
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      // If check fails, allow transaction to continue
      print('Budget check error: $e');
      return true;
    }
  }

  Widget _buildBudgetInfoRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Check if this expense would exceed any budget
    if (_isExpense) {
      final shouldContinue = await _checkBudgetLimit(amount);
      if (!shouldContinue) return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final title = _titleController.text.trim();
      final notes = _notesController.text.trim();

      final category = ref
          .read(categoryProvider.notifier)
          .getCategoryById(_selectedCategoryId!);

      if (category == null) {
        throw Exception('Selected category not found');
      }

      if (widget.transaction == null) {
        final transaction = Transaction(
          id: const Uuid().v4(),
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          amount: amount,
          title: title.isEmpty ? category.name : title,
          notes: notes.isEmpty ? null : notes,
          date: _selectedDate.millisecondsSinceEpoch,
          createdAt: now,
          updatedAt: now,
        );

        final success = await ref
            .read(transactionProvider.notifier)
            .addTransaction(transaction, category);

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            final error = ref.read(transactionProvider).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Failed to add transaction'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        final updatedTransaction = Transaction(
          id: widget.transaction!.id,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          amount: amount,
          title: title.isEmpty ? category.name : title,
          notes: notes.isEmpty ? null : notes,
          date: _selectedDate.millisecondsSinceEpoch,
          createdAt: widget.transaction!.createdAt,
          updatedAt: now,
        );

        final success = await ref
            .read(transactionProvider.notifier)
            .updateTransaction(
              _oldTransaction!,
              updatedTransaction,
              _oldCategory!,
              category,
            );

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            final error = ref.read(transactionProvider).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Failed to update transaction'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconData(String iconName) {
    return _iconMap[iconName] ?? Icons.category;
  }
}

// ============================================================================
// Category Picker Bottom Sheet
// ============================================================================

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final bool isExpense;
  final Function(String) onCategorySelected;
  final VoidCallback onCategoryCreated;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.isExpense,
    required this.onCategorySelected,
    required this.onCategoryCreated,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: widget.categories.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                // Add new category button
                if (index == widget.categories.length) {
                  return _buildAddCategoryButton();
                }

                final category = widget.categories[index];
                final isSelected = widget.selectedCategoryId == category.id;

                return GestureDetector(
                  onTap: () {
                    widget.onCategorySelected(category.id);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Color(category.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: Color(category.color),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(
                          _iconMap[category.iconName] ?? Icons.category,
                          color: Color(category.color),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: () => _showAddCategoryDialog(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade400,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(Icons.add, color: Colors.grey, size: 28),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add New',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    Navigator.pop(context); // Close category picker first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddCategorySheet(
        isExpense: widget.isExpense,
        onCategoryCreated: widget.onCategoryCreated,
      ),
    );
  }
}

// ============================================================================
// Add Category Bottom Sheet
// ============================================================================

class _AddCategorySheet extends ConsumerStatefulWidget {
  final bool isExpense;
  final VoidCallback onCategoryCreated;

  const _AddCategorySheet({
    required this.isExpense,
    required this.onCategoryCreated,
  });

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _nameController = TextEditingController();
  String _selectedIconName = 'category';
  int _selectedColor = 0xFF2196F3;
  bool _isLoading = false;

  final List<int> _availableColors = [
    0xFFF44336, // Red
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF03A9F4, // Light Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFF8BC34A, // Light Green
    0xFFCDDC39, // Lime
    0xFFFFEB3B, // Yellow
    0xFFFFC107, // Amber
    0xFFFF9800, // Orange
    0xFFFF5722, // Deep Orange
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Add New Category',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Preview
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(_selectedColor).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _iconMap[_selectedIconName] ?? Icons.category,
                        color: Color(_selectedColor),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Groceries',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),

                  // Color Selection
                  const Text(
                    'Select Color',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Icon Selection
                  const Text(
                    'Select Icon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: _iconMap.length,
                    itemBuilder: (context, index) {
                      final iconEntry = _iconMap.entries.elementAt(index);
                      final isSelected = _selectedIconName == iconEntry.key;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedIconName = iconEntry.key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(_selectedColor).withValues(alpha: 0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: Color(_selectedColor),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            iconEntry.value,
                            color: isSelected
                                ? Color(_selectedColor)
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final category = Category(
        id: const Uuid().v4(),
        name: name,
        iconName: _selectedIconName,
        color: _selectedColor,
        type: widget.isExpense ? 'expense' : 'income',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await ref.read(categoryProvider.notifier).createCategory(category);

      final error = ref.read(categoryProvider).error;
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      } else {
        widget.onCategoryCreated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ============================================================================
// Icon Map (shared across widgets)
// ============================================================================

const Map<String, IconData> _iconMap = {
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
  'checkroom': Icons.checkroom,
  'fitness_center': Icons.fitness_center,
  'pets': Icons.pets,
  'card_giftcard': Icons.card_giftcard,
  'more_horiz': Icons.more_horiz,
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
  'egg_alt': Icons.egg_alt,
  'train': Icons.train,
  'account_balance_wallet': Icons.account_balance_wallet,
  'category': Icons.category,
  'shopping_bag': Icons.shopping_bag,
  'local_grocery_store': Icons.local_grocery_store,
  'theaters': Icons.theaters,
  'beach_access': Icons.beach_access,
  'child_care': Icons.child_care,
  'cake': Icons.cake,
  'favorite': Icons.favorite,
  'star': Icons.star,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'local_laundry_service': Icons.local_laundry_service,
  'build': Icons.build,
  'brush': Icons.brush,
  'book': Icons.book,
  'headphones': Icons.headphones,
  'videogame_asset': Icons.videogame_asset,
  'sports_soccer': Icons.sports_soccer,
  'sports_basketball': Icons.sports_basketball,
  'directions_bike': Icons.directions_bike,
  'directions_bus': Icons.directions_bus,
  'local_taxi': Icons.local_taxi,
};
