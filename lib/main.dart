import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/seeding_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/more/more_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/budgets/budgets_screen.dart';
import 'providers/settings_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool showOnboarding = true;

  try {
    final db = DatabaseService();
    await db.database;

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      final seedingService = SeedingService(db);
      await seedingService.seedDefaultData();
      await prefs.setBool('first_launch', false);
      await prefs.setBool('show_onboarding', true);
    }

    showOnboarding = prefs.getBool('show_onboarding') ?? true;
  } catch (e) {
    debugPrint('Initialization failed: $e');
  }

  runApp(ProviderScope(child: CashChewApp(showOnboarding: showOnboarding)));
}

class CashChewApp extends ConsumerWidget {
  final bool showOnboarding;

  const CashChewApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;

    return MaterialApp(
      title: 'CashChew',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(accentColor),
      darkTheme: _buildDarkTheme(accentColor),
      themeMode: ThemeMode.system,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: showOnboarding ? const OnboardingScreen() : const MainNavigation(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/transactions': (context) => const TransactionsScreen(),
      },
    );
  }

  ThemeData _buildLightTheme(Color accentColor) {
    final secondaryColor = HSLColor.fromColor(
      accentColor,
    ).withSaturation(0.3).withLightness(0.92).toColor();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        secondary: secondaryColor,
        surface: const Color(0xFFF5F6FA),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: secondaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryColor,
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
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: HSLColor.fromColor(
          accentColor,
        ).withLightness(0.4).toColor(),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      ),
    );
  }
}

/// Main Navigation with Bottom Navigation Bar
class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _MainNavigationContent();
  }
}

class _MainNavigationContent extends StatefulWidget {
  const _MainNavigationContent();

  @override
  State<_MainNavigationContent> createState() => _MainNavigationContentState();
}

class _MainNavigationContentState extends State<_MainNavigationContent> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

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
          selectedItemColor: accentColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: l10n.transactions,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart_outline),
              activeIcon: const Icon(Icons.pie_chart),
              label: l10n.budgets,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              activeIcon: const Icon(Icons.menu),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
