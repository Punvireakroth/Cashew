import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../utils/currency_formatter.dart';

/// Screen for creating or editing an account
/// Styled to match Cashew app design
class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedCurrency = 'USD';
  bool _isSaving = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toStringAsFixed(2);
      _selectedCurrency = widget.account!.currency;
    } else {
      _balanceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account name is required';
    }
    if (value.trim().length > 50) {
      return 'Account name must be 50 characters or less';
    }
    return null;
  }

  String? _validateBalance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Balance is required';
    }

    final parsed = CurrencyFormatter.parse(value);
    if (parsed == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  Future<void> _saveAccount() async {
    ref.read(accountProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final balance = CurrencyFormatter.parse(_balanceController.text) ?? 0.0;

      final account = Account(
        id: _isEditing ? widget.account!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        balance: balance,
        currency: _selectedCurrency,
        createdAt: _isEditing ? widget.account!.createdAt : now,
        updatedAt: now,
      );

      final success = _isEditing
          ? await ref.read(accountProvider.notifier).updateAccount(account)
          : await ref.read(accountProvider.notifier).createAccount(account);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Account updated successfully'
                  : 'Account created successfully',
            ),
            backgroundColor: const Color(0xFF7BD389),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        final error = ref.read(accountProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save account'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Account' : 'Add Account',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Account name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., Cash, Bank Account, Savings',
                labelStyle: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textCapitalization: TextCapitalization.words,
              validator: _validateName,
              enabled: !_isSaving,
              maxLength: 50,
            ),
            const SizedBox(height: 8),

            // Balance field
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Current Balance' : 'Initial Balance',
                hintText: '0.00',
                labelStyle: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                helperText: 'Enter the current balance for this account',
                helperStyle: const TextStyle(color: Colors.black45),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: _validateBalance,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 8),

            // Currency selector
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBFA),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  labelStyle: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                dropdownColor: const Color(0xFFE8EBFA),
                items: CurrencyFormatter.getSupportedCurrencies()
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Row(
                          children: [
                            Text(
                              CurrencyFormatter.getCurrencySymbol(currency),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currency,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.getCurrencyName(currency),
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveAccount,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Account' : 'Create Account',
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
}
