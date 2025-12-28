import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';

/// Enhanced Onboarding screen with user setup flow
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _nameController = TextEditingController();
  final _accountNameController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _isCreating = false;

  static const _introPages = [
    _OnboardingPage(
      icon: Icons.account_balance_wallet,
      title: 'Welcome to CashChew',
      description:
          'Your personal finance companion that helps you track, manage, and understand your money better.',
      color: Color(0xFF6B7FD7),
    ),
    _OnboardingPage(
      icon: Icons.receipt_long,
      title: 'Track Your Finances',
      description:
          'Easily record income and expenses with categories to keep your finances organized.',
      color: Color(0xFF4CAF50),
    ),
    _OnboardingPage(
      icon: Icons.pie_chart,
      title: 'Set Budgets & Goals',
      description:
          'Create monthly budgets and track your spending to stay on top of your financial goals.',
      color: Color(0xFFFF9800),
    ),
    _OnboardingPage(
      icon: Icons.insights,
      title: 'Visualize & Analyze',
      description:
          'Get insights into your spending patterns with beautiful charts and statistics.',
      color: Color(0xFF9C27B0),
    ),
  ];

  static const _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
    {'code': 'KHR', 'symbol': '៛', 'name': 'Cambodian Riel'},
    {'code': 'THB', 'symbol': '฿', 'name': 'Thai Baht'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'KRW', 'symbol': '₩', 'name': 'Korean Won'},
    {'code': 'SGD', 'symbol': '\$', 'name': 'Singapore Dollar'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
    {'code': 'AUD', 'symbol': '\$', 'name': 'Australian Dollar'},
  ];

  int get _totalPages => _introPages.length + 4;
  bool get _isSetupPhase => _currentPage >= _introPages.length;
  int get _namePageIndex => _introPages.length;
  int get _currencyPageIndex => _introPages.length + 1;
  int get _accountPageIndex => _introPages.length + 2;
  int get _successPageIndex => _introPages.length + 3;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _accountNameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _accountNameController.removeListener(_onTextChanged);
    _pageController.dispose();
    _nameController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  bool _canProceed() {
    if (_currentPage == _namePageIndex) {
      return _nameController.text.trim().isNotEmpty;
    }
    if (_currentPage == _currencyPageIndex) {
      return _selectedCurrency.isNotEmpty;
    }
    if (_currentPage == _accountPageIndex) {
      return _accountNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  bool get _shouldDisableButton {
    if (_isCreating) return true;
    if (_currentPage < _introPages.length) return false;
    if (_currentPage == _successPageIndex) return false;
    return !_canProceed();
  }

  Future<void> _nextPage() async {
    if (_currentPage == _accountPageIndex) {
      await _createAccountAndComplete();
    } else if (_currentPage == _successPageIndex) {
      _navigateToHome();
    } else if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createAccountAndComplete() async {
    if (!_canProceed()) return;

    setState(() => _isCreating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_display_name', _nameController.text.trim());
      await prefs.setString('default_currency', _selectedCurrency);
      await prefs.setBool('show_onboarding', false);

      final now = DateTime.now().millisecondsSinceEpoch;
      final account = Account(
        id: const Uuid().v4(),
        name: _accountNameController.text.trim(),
        balance: 0.0,
        currency: _selectedCurrency,
        createdAt: now,
        updatedAt: now,
      );

      final success = await ref
          .read(accountProvider.notifier)
          .createAccount(account);

      if (!mounted) return;

      if (success) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        final error = ref.read(accountProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to create account'),
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
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Visibility(
              visible: _isSetupPhase && _currentPage != _successPageIndex,
              maintainState: true,
              maintainSize: false,
              maintainAnimation: true,
              child: _buildProgressIndicator(),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('onboarding_pageview'),
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index < _introPages.length) {
                    return _IntroPageView(page: _introPages[index]);
                  } else if (index == _namePageIndex) {
                    return _NamePage(controller: _nameController);
                  } else if (index == _currencyPageIndex) {
                    return _CurrencyPage(
                      currencies: _currencies,
                      selectedCurrency: _selectedCurrency,
                      onCurrencySelected: (code) {
                        setState(() => _selectedCurrency = code);
                      },
                    );
                  } else if (index == _accountPageIndex) {
                    return _AccountPage(
                      controller: _accountNameController,
                      selectedCurrency: _selectedCurrency,
                      currencies: _currencies,
                    );
                  } else {
                    return _SuccessPage(
                      userName: _nameController.text.trim(),
                      accountName: _accountNameController.text.trim(),
                      currency: _selectedCurrency,
                    );
                  }
                },
              ),
            ),
            Visibility(
              visible: !_isSetupPhase,
              maintainState: true,
              maintainSize: false,
              maintainAnimation: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _introPages.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final setupStep = _currentPage - _introPages.length;
    const totalSetupSteps = 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${setupStep + 1} of $totalSetupSteps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${((setupStep + 1) / totalSetupSteps * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (setupStep + 1) / totalSetupSteps,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBottomButton() {
    String buttonText;
    if (_currentPage < _introPages.length) {
      buttonText = _currentPage == _introPages.length - 1
          ? "Let's Get Started"
          : 'Next';
    } else if (_currentPage == _accountPageIndex) {
      buttonText = 'Create Account';
    } else if (_currentPage == _successPageIndex) {
      buttonText = 'Start Using CashChew';
    } else {
      buttonText = 'Continue';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _shouldDisableButton ? null : _nextPage,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6B7FD7),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// Extracted Page Widgets
// ============================================================================

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _IntroPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _IntroPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 70, color: page.color),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;

  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7FD7).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 40,
              color: Color(0xFF6B7FD7),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "What's your name?",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalize your experience",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6B7FD7),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatelessWidget {
  final List<Map<String, String>> currencies;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  const _CurrencyPage({
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money,
                  size: 40,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Choose your currency',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This will be your default currency for new accounts",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              final isSelected = selectedCurrency == currency['code'];

              return GestureDetector(
                onTap: () => onCurrencySelected(currency['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6B7FD7).withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6B7FD7)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currency['symbol']!,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF6B7FD7)
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency['code']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF6B7FD7)
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency['name']!,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountPage extends StatelessWidget {
  final TextEditingController controller;
  final String selectedCurrency;
  final List<Map<String, String>> currencies;

  const _AccountPage({
    required this.controller,
    required this.selectedCurrency,
    required this.currencies,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currencies.firstWhere(
      (c) => c['code'] == selectedCurrency,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Create your first account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Give it a name to help you track your money",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: 'e.g., Cash, Wallet, Bank',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6B7FD7),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _QuickSuggestions(controller: controller),
          const SizedBox(height: 32),
          _AccountPreview(
            controller: controller,
            currencySymbol: currencySymbol,
            currencyCode: selectedCurrency,
          ),
        ],
      ),
    );
  }
}

class _QuickSuggestions extends StatelessWidget {
  final TextEditingController controller;

  const _QuickSuggestions({required this.controller});

  @override
  Widget build(BuildContext context) {
    const suggestions = ['Cash', 'Wallet', 'Bank Account', 'Savings'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((name) {
        final isSelected = controller.text == name;
        return GestureDetector(
          onTap: () => controller.text = name,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6B7FD7).withOpacity(0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6B7FD7)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6B7FD7) : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccountPreview extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final String currencyCode;

  const _AccountPreview({
    required this.controller,
    required this.currencySymbol,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7FD7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF6B7FD7),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.text.isEmpty ? 'Account Name' : controller.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: controller.text.isEmpty
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol 0.00',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            currencyCode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessPage extends StatelessWidget {
  final String userName;
  final String accountName;
  final String currency;

  const _SuccessPage({
    required this.userName,
    required this.accountName,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            "You're all set!",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome, $userName! Your account "$accountName" is ready.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SummaryRow(icon: Icons.person, label: 'Name', value: userName),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.attach_money,
                  label: 'Currency',
                  value: currency,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.account_balance_wallet,
                  label: 'Account',
                  value: accountName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF6B7FD7)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
