import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/database_service.dart';
import 'services/seeding_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/accounts/accounts_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'widgets/transaction_item.dart';
import 'utils/currency_formatter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and seed default data on first launch
  print('Initializing CashChew...');

  bool showOnboarding = true;

  try {
    final db = DatabaseService();
    final database = await db.database;
    final version = await db.getVersion();

    print('Database initialized successfully!');
    print('Database version: $version');

    // Get list of tables to verify creation
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    print('Tables created: ${tables.map((t) => t['name']).join(', ')}');

    // Check if first launch and seed default data
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      print('First launch detected - seeding default data...');
      final seedingService = SeedingService(db);
      await seedingService.seedDefaultData();
      await prefs.setBool('first_launch', false);
      await prefs.setBool('show_onboarding', true);
      print('Default data seeded successfully!');
    }

    // Check if should show onboarding
    showOnboarding = prefs.getBool('show_onboarding') ?? true;
  } catch (e) {
    print('Initialization failed: $e');
  }

  runApp(ProviderScope(child: MyApp(showOnboarding: showOnboarding)));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashChew',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B7FD7), // Cashew purple/indigo
          brightness: Brightness.light,
          primary: const Color(0xFF6B7FD7),
          secondary: const Color(0xFFE8EBFA),
          surface: const Color(0xFFF5F6FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFFE8EBFA),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE8EBFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6B7FD7), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6B7FD7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF5A6B9E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B7FD7),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: showOnboarding ? const OnboardingScreen() : const MainNavigation(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/accounts': (context) => const AccountsScreen(),
        '/transactions': (context) => const TransactionsScreen(),
      },
    );
  }
}

/// Main Navigation with Bottom Navigation Bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6B7FD7),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              activeIcon: Icon(Icons.menu),
              label: 'More',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }
}

/// Home Screen with 5 sections
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedTransactionType = 'All'; // All, Expense, Income

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).loadAccounts();
      ref.read(categoryProvider.notifier).loadCategories();
      ref.read(transactionProvider.notifier).loadTransactions(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final transactionState = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F6FA),
            elevation: 0,
            floating: true,
            snap: true,
            title: const Text(
              'What\'s up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  // 2. Account Section
                  _buildAccountSection(accountState),
                  const SizedBox(height: 24),

                  // 3. Budget Section (if exists)
                  _buildBudgetSection(),
                  const SizedBox(height: 24),

                  // 4. Spending Graph
                  _buildSpendingGraph(accountState),
                  const SizedBox(height: 24),

                  // 5. Transaction Tabs Section
                  _buildTransactionTabs(transactionState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Welcome Section
  Widget _buildWelcomeSection() {
    final accountState = ref.watch(accountProvider);
    final totalBalance = accountState.accounts.fold<double>(
      0.0,
      (sum, acc) => sum + acc.balance,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pun VireakRoth',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Balance: ${CurrencyFormatter.format(totalBalance)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  // 2. Account Section
  Widget _buildAccountSection(AccountState accountState) {
    if (accountState.accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EBFA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No accounts yet',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accountState.accounts.length,
        itemBuilder: (context, index) {
          final account = accountState.accounts[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? const Color(0xFFE8EBFA) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: index % 2 != 0
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? Colors.grey.shade400
                            : const Color(0xFF6B7FD7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(account.balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getTransactionCount(account.id)} transactions',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getTransactionCount(String accountId) {
    final transactions = ref.read(transactionProvider).transactions;
    return transactions.where((tx) => tx.accountId == accountId).length;
  }

  // 3. Budget Section
  Widget _buildBudgetSection() {
    // Mock budget data for now (will be replaced in Phase 5)
    // TODO: Replace with real budget data in Phase 5
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBFA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saving',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '\$100 left of \$100',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Yesterday',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7FD7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                'Dec 23',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'You can spend \$3.45/day for 29 more days',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Spending Graph
  Widget _buildSpendingGraph(AccountState accountState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Spending Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dates = [
                          'Oct 25',
                          'Nov 2',
                          'Nov 10',
                          'Nov 17',
                          'Nov 25',
                        ];
                        if (value.toInt() >= 0 &&
                            value.toInt() < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dates[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 4,
                minY: 550,
                maxY: 590,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 583),
                      FlSpot(1, 574),
                      FlSpot(2, 564),
                      FlSpot(3, 555),
                      FlSpot(4, 555),
                    ],
                    isCurved: true,
                    color: const Color(0xFF6B7FD7),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6B7FD7).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Transaction Tabs Section
  Widget _buildTransactionTabs(TransactionState transactionState) {
    return Column(
      children: [
        // Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBFA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTabButton('All')),
              Expanded(child: _buildTabButton('Expense')),
              Expanded(child: _buildTabButton('Income')),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Transaction List
        _buildTransactionList(transactionState),
      ],
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = _selectedTransactionType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTransactionType = label;
        });
        // Apply filter
        if (label == 'All') {
          ref.read(transactionProvider.notifier).setTypeFilter(null);
        } else if (label == 'Expense') {
          ref.read(transactionProvider.notifier).setTypeFilter('expense');
        } else {
          ref.read(transactionProvider.notifier).setTypeFilter('income');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionState transactionState) {
    if (transactionState.isLoading && transactionState.transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (transactionState.transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    // Show first 5 transactions
    final displayTransactions = transactionState.transactions.take(5).toList();

    return Column(
      children: [
        ...displayTransactions.map((transaction) {
          return TransactionItem(
            transaction: transaction,
            onTap: () {
              // Navigate to transaction detail/edit
            },
          );
        }),
        if (transactionState.transactions.length > 5)
          TextButton(
            onPressed: () {
              // Navigate to full transactions screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionsScreen(),
                ),
              );
            },
            child: const Text('See all transactions'),
          ),
      ],
    );
  }
}

// Placeholder screens for Budgets and More
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Budgets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 5',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
