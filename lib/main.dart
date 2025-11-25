import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/seeding_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/accounts/accounts_screen.dart';
import 'providers/account_provider.dart';
import 'widgets/account_card.dart';

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
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/accounts': (context) => const AccountsScreen(),
      },
    );
  }
}

/// Temporary home screen for Phase 3
/// Will be replaced with full dashboard in Phase 6
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'CashChew',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome text
          Text(
            'Welcome back! 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your financial overview',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Accounts section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Accounts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountsScreen(),
                    ),
                  );
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Accounts horizontal list
          if (accountState.isLoading && accountState.accounts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (accountState.accounts.isEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBFA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: Colors.black38,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No accounts yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AccountsScreen(),
                          ),
                        );
                      },
                      child: const Text('Add Account'),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: accountState.accounts.length,
                itemBuilder: (context, index) {
                  final account = accountState.accounts[index];
                  return AccountCard(
                    account: account,
                    transactionCount: 0,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AccountsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 32),

          // Coming soon card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBFA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'More features coming soon!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Transactions, budgets, and statistics will be available in the next phases.',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AccountsScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
