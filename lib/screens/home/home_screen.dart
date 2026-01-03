import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../l10n/app_localizations.dart';
import '../transactions/transactions_screen.dart';
import 'widgets/welcome_section.dart';
import 'widgets/account_section.dart';
import 'widgets/budget_section.dart';
import 'widgets/spending_graph.dart';
import 'widgets/transaction_tabs.dart';

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
      ref.read(categoryProvider.notifier).loadCategories();
      ref.read(transactionProvider.notifier).loadTransactions(refresh: true);
      ref.read(budgetProvider.notifier).loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F6FA),
            elevation: 0,
            floating: true,
            snap: true,
            title: Text(
              l10n.whatsUp,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  WelcomeSection(),
                  SizedBox(height: 24),
                  AccountSection(),
                  SizedBox(height: 24),
                  BudgetSection(),
                  SizedBox(height: 24),
                  SpendingGraph(),
                  SizedBox(height: 24),
                  TransactionTabs(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
