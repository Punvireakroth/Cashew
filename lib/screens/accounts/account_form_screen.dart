import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedCurrency = 'USD';
  int _selectedColorIndex = 0;
  int _decimalPrecision = 2;
  bool _isSaving = false;
  String _searchQuery = '';

  bool get _isEditing => widget.account != null;

  // Available colors for account
  final List<Color> _accountColors = [
    const Color(0xFF6B7B3D), // Olive (with palette icon)
    const Color(0xFF4CAF50), // Green
    const Color(0xFF673AB7), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFFFF9800), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFFF44336), // Red
    const Color(0xFF795548), // Brown
  ];

  // Currency data with more details
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'United States'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro Member'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japan'},
    {'code': 'GBP', 'symbol': '£', 'name': 'United Kingdom'},
    {'code': 'AUD', 'symbol': '\$', 'name': 'Australia'},
    {'code': 'CAD', 'symbol': '\$', 'name': 'Canada'},
    {'code': 'CHF', 'symbol': 'F', 'name': 'Switzerland'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'China'},
    {'code': 'SEK', 'symbol': 'kr', 'name': 'Sweden'},
    {'code': 'KHR', 'symbol': '៛', 'name': 'Cambodia'},
    {'code': 'THB', 'symbol': '฿', 'name': 'Thailand'},
    {'code': 'INR', 'symbol': '₹', 'name': 'India'},
    {'code': 'KRW', 'symbol': '₩', 'name': 'South Korea'},
    {'code': 'SGD', 'symbol': '\$', 'name': 'Singapore'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysia'},
  ];

  List<Map<String, String>> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return _currencies;
    return _currencies.where((c) {
      final code = c['code']!.toLowerCase();
      final name = c['name']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });

    if (_isEditing) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toStringAsFixed(2);
      _selectedCurrency = widget.account!.currency;
    } else {
      _balanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an account name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final balance = double.tryParse(_balanceController.text) ?? 0.0;

      final account = Account(
        id: _isEditing ? widget.account!.id : const Uuid().v4(),
        name: name,
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
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(accountProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final currencySymbol = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Account' : 'Add Account',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  _buildNameField(),
                  const SizedBox(height: 20),

                  // Color Selection
                  _buildColorSelection(),
                  const SizedBox(height: 24),

                  // Starting Balance
                  _buildBalanceSection(currencySymbol, balance),
                  const SizedBox(height: 16),

                  // Decimal Precision
                  _buildDecimalPrecisionOption(),
                  const SizedBox(height: 24),

                  // Currency Search
                  _buildCurrencySearch(),
                  const SizedBox(height: 16),

                  // Currency Grid
                  _buildCurrencyGrid(),
                ],
              ),
            ),
          ),

          // Bottom Button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: 'Name',
          hintStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildColorSelection() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _accountColors.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedColorIndex == index;
          final color = _accountColors[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedColorIndex = index),
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
              ),
              child: index == 0
                  ? const Icon(Icons.palette, color: Colors.white, size: 24)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceSection(String currencySymbol, double balance) {
    return GestureDetector(
      onTap: _showBalanceDialog,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Starting at',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currencySymbol${balance.toStringAsFixed(_decimalPrecision)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecimalPrecisionOption() {
    return GestureDetector(
      onTap: _showDecimalPrecisionDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.pin, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 12),
            const Text(
              'Decimal Precision',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '$_decimalPrecision',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: Icon(Icons.search, color: Colors.grey[500]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            // Show info about currencies
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select your preferred currency')),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Icon(Icons.info_outline, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        final isSelected = _selectedCurrency == currency['code'];

        return GestureDetector(
          onTap: () => setState(() => _selectedCurrency = currency['code']!),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE8E8D0)
                  : const Color(0xFFF5F5E8),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF6B7B3D), width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currency['code']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency['symbol']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency['name']!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
            onPressed: _isSaving ? null : _saveAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7B3D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Update Account' : 'Set Name',
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

  void _showBalanceDialog() {
    final controller = TextEditingController(text: _balanceController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Starting Balance'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            hintText: '0.00',
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
              setState(
                () => _balanceController.text = controller.text.isEmpty
                    ? '0'
                    : controller.text,
              );
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDecimalPrecisionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decimal Precision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0, 1, 2, 3].map((precision) {
            return RadioListTile<int>(
              title: Text('$precision decimal places'),
              subtitle: Text(
                'e.g., ${precision == 0
                    ? "100"
                    : precision == 1
                    ? "100.0"
                    : precision == 2
                    ? "100.00"
                    : "100.000"}',
              ),
              value: precision,
              groupValue: _decimalPrecision,
              onChanged: (value) {
                setState(() => _decimalPrecision = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
