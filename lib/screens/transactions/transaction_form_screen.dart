import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction; // For editing

  const TransactionFormScreen({Key? key, this.transaction}) : super(key: key);

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  bool _isLoading = false;

  // Store old transaction data for editing
  Transaction? _oldTransaction;
  Category? _oldCategory;

  @override
  void initState() {
    super.initState();

    // Load categories and accounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
      ref.read(accountProvider.notifier).loadAccounts();

      if (widget.transaction != null) {
        _populateForm();
      }
    });
  }

  void _populateForm() {
    final transaction = widget.transaction!;
    _oldTransaction = transaction;

    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toString();
    _notesController.text = transaction.notes ?? '';
    _selectedAccountId = transaction.accountId;
    _selectedCategoryId = transaction.categoryId;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(transaction.date);

    // Determine transaction type from category
    final category = ref.read(categoryProvider.notifier)
        .getCategoryById(transaction.categoryId);
    if (category != null) {
      _oldCategory = category;
      setState(() {
        _isExpense = category.isExpense;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final accountState = ref.watch(accountProvider);

    final categories = _isExpense
        ? categoryState.categories.where((cat) => cat.isExpense).toList()
        : categoryState.categories.where((cat) => cat.isIncome).toList();

    final accounts = accountState.accounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Income/Expense Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_upward, color: Colors.green),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_downward, color: Colors.red),
                    ),
                  ],
                  selected: {_isExpense},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isExpense = newSelection.first;
                      // Reset category selection when switching type
                      _selectedCategoryId = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Grocery shopping',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 2) {
                  return 'Title must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Title must be less than 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Account',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: accounts.map((Account account) {
                return DropdownMenuItem<String>(
                  value: account.id,
                  child: Text(account.name),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedAccountId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: const OutlineInputBorder(),
                helperText: categories.isEmpty
                    ? 'No ${_isExpense ? "expense" : "income"} categories available'
                    : null,
              ),
              items: categories.map((Category category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        _getIconData(category.iconName),
                        color: Color(category.color),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: categories.isEmpty
                  ? null
                  : (String? value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),

            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional details',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value != null && value.length > 200) {
                  return 'Notes must be less than 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveTransaction,
              icon: const Icon(Icons.save),
              label: Text(widget.transaction == null ? 'Add Transaction' : 'Update Transaction'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final amount = double.parse(_amountController.text);
      final title = _titleController.text.trim();
      final notes = _notesController.text.trim();

      // Get the selected category
      final category = ref.read(categoryProvider.notifier)
          .getCategoryById(_selectedCategoryId!);

      if (category == null) {
        throw Exception('Selected category not found');
      }

      if (widget.transaction == null) {
        // Create new transaction
        final transaction = Transaction(
          id: const Uuid().v4(),
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          amount: amount,
          title: title,
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
        // Update existing transaction
        final updatedTransaction = Transaction(
          id: widget.transaction!.id,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          amount: amount,
          title: title,
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
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    };

    return iconMap[iconName] ?? Icons.category;
  }
}

