import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../utils/currency_formatter.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  final Budget? budget; // For editing

  const BudgetFormScreen({super.key, this.budget});

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Populate form with existing budget data
      _nameController.text = widget.budget!.name;
      _limitController.text = widget.budget!.limitAmount.toStringAsFixed(0);
      _startDate = DateTime.fromMillisecondsSinceEpoch(
        widget.budget!.startDate,
      );
      _endDate = DateTime.fromMillisecondsSinceEpoch(widget.budget!.endDate);
    } else {
      // Default to current month
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0); // Last day of month
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
            ).colorScheme.copyWith(primary: const Color(0xFF606C38)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final limitAmount = double.parse(
        _limitController.text.replaceAll(RegExp(r'[^\d.]'), ''),
      );

      final budget = Budget(
        id: _isEditing ? widget.budget!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        limitAmount: limitAmount,
        startDate: _startDate.millisecondsSinceEpoch,
        endDate: _endDate.millisecondsSinceEpoch,
        createdAt: _isEditing ? widget.budget!.createdAt : now,
        updatedAt: now,
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(budgetProvider.notifier).updateBudget(budget);
      } else {
        success = await ref.read(budgetProvider.notifier).createBudget(budget);
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
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
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
                hintText: 'e.g., Groceries, Entertainment',
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

            // Budget Period
            _buildSectionTitle('Budget Period'),
            const SizedBox(height: 8),

            // Quick period selection
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
                      '${CurrencyFormatter.format(double.tryParse(_limitController.text) ?? 0 / (_endDate.difference(_startDate).inDays + 1))}/day',
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
              Navigator.pop(context); // Close dialog
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
