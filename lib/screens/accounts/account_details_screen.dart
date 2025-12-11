import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/account.dart';
import '../../models/transaction.dart' as tx;
import '../../models/category.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/currency_formatter.dart';
import '../transactions/transaction_form_screen.dart';
import 'account_form_screen.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  int _selectedTabIndex = 0; // 0 = Outgoing, 1 = Incoming

  Account get _currentAccount {
    // Get updated account from provider
    final accounts = ref.watch(accountProvider).accounts;
    return accounts.firstWhere(
      (a) => a.id == widget.account.id,
      orElse: () => widget.account,
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = _currentAccount;
    final transactionState = ref.watch(transactionProvider);
    final categoryState = ref.watch(categoryProvider);

    // Filter transactions for this account
    final accountTransactions = transactionState.transactions
        .where((t) => t.accountId == account.id)
        .toList();

    // Calculate summary
    final summary = _calculateSummary(accountTransactions, categoryState);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(account),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountTotalCard(account, accountTransactions.length),
            const SizedBox(height: 16),
            _buildTimeFilter(),
            const SizedBox(height: 16),
            _buildSummaryCard(summary),
            const SizedBox(height: 16),
            _buildChartCard(accountTransactions, categoryState),
            const SizedBox(height: 16),
            _buildCategoryTabs(accountTransactions, categoryState),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTransaction(),
        backgroundColor: const Color(0xFF6B7B3D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Account account) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F6FA),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        account.name.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.black87),
          onPressed: () => _navigateToEdit(account),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(account);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Account', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountTotalCard(Account account, int transactionCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E4D9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Account Total',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            '${CurrencyFormatter.format(account.balance)} ${account.currency}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$transactionCount transactions',
            style: const TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          const Text(
            'All Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(_TransactionSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Expense',
            summary.expenseCount,
            summary.totalExpense,
            const Color(0xFFE57373),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Income',
            summary.incomeCount,
            summary.totalIncome,
            const Color(0xFF81C784),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Balance Correction',
            summary.correctionCount,
            summary.totalCorrection,
            Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int count, double amount, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: '  (×$count)',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
        const SizedBox(width: 12),
        Text(
          amount < 0
              ? '-${CurrencyFormatter.format(amount.abs())}'
              : CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    List<tx.Transaction> transactions,
    CategoryState categoryState,
  ) {
    final chartData = _generateChartData(transactions, categoryState);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        height: 200,
        child: chartData.isEmpty
            ? const Center(
                child: Text(
                  'No data to display',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(chartData),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '\$${value.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final labels = _getMonthLabels(transactions);
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: const Color(0xFF6B7B3D),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6B7B3D).withOpacity(0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF6B7B3D),
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryTabs(
    List<tx.Transaction> transactions,
    CategoryState categoryState,
  ) {
    return Column(
      children: [
        // Tab buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 0
                          ? const Color(0xFFE8E4D9)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: _selectedTabIndex == 0
                              ? Colors.red
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Outgoing',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 0
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 1
                          ? const Color(0xFFE8E4D9)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: _selectedTabIndex == 1
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Incoming',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 1
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Pie chart
        _buildPieChart(transactions, categoryState),
      ],
    );
  }

  Widget _buildPieChart(
    List<tx.Transaction> transactions,
    CategoryState categoryState,
  ) {
    final type = _selectedTabIndex == 0 ? 'expense' : 'income';
    final categoryTotals = _getCategoryTotals(
      transactions,
      categoryState,
      type,
    );

    if (categoryTotals.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text('No transactions', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: categoryTotals.entries.map((entry) {
              final category = categoryState.categories.firstWhere(
                (c) => c.id == entry.key,
                orElse: () => Category(
                  id: entry.key,
                  name: 'Unknown',
                  iconName: 'help',
                  color: Colors.grey.value,
                  type: type,
                  createdAt: 0,
                ),
              );
              return PieChartSectionData(
                value: entry.value,
                color: Color(category.color),
                radius: 50,
                title: '',
                badgeWidget: _buildCategoryBadge(category),
                badgePositionPercentageOffset: 1.3,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(Category category) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(category.color),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getCategoryIcon(category.iconName),
        size: 16,
        color: Colors.white,
      ),
    );
  }

  // Helper methods
  _TransactionSummary _calculateSummary(
    List<tx.Transaction> transactions,
    CategoryState categoryState,
  ) {
    double totalExpense = 0;
    double totalIncome = 0;
    double totalCorrection = 0;
    int expenseCount = 0;
    int incomeCount = 0;
    int correctionCount = 0;

    for (final transaction in transactions) {
      final category = categoryState.categories.firstWhere(
        (c) => c.id == transaction.categoryId,
        orElse: () => Category(
          id: '',
          name: 'Unknown',
          iconName: 'help',
          color: Colors.grey.value,
          type: 'expense',
          createdAt: 0,
        ),
      );

      if (category.name.toLowerCase().contains('correction') ||
          category.name.toLowerCase().contains('adjustment')) {
        totalCorrection += transaction.amount;
        correctionCount++;
      } else if (category.isExpense) {
        totalExpense += transaction.amount;
        expenseCount++;
      } else {
        totalIncome += transaction.amount;
        incomeCount++;
      }
    }

    return _TransactionSummary(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      totalCorrection: totalCorrection,
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      correctionCount: correctionCount,
    );
  }

  List<FlSpot> _generateChartData(
    List<tx.Transaction> transactions,
    CategoryState categoryState,
  ) {
    if (transactions.isEmpty) return [];

    // Group transactions by month and calculate cumulative balance
    final Map<int, double> monthlyData = {};
    final sortedTransactions = List<tx.Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0;
    for (final transaction in sortedTransactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);
      final monthKey = date.year * 12 + date.month;

      final category = categoryState.categories.firstWhere(
        (c) => c.id == transaction.categoryId,
        orElse: () => Category(
          id: '',
          name: 'Unknown',
          iconName: 'help',
          color: Colors.grey.value,
          type: 'expense',
          createdAt: 0,
        ),
      );

      if (category.isIncome) {
        runningBalance += transaction.amount;
      } else {
        runningBalance -= transaction.amount;
      }
      monthlyData[monthKey] = runningBalance;
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    return sortedKeys.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), monthlyData[entry.value]!);
    }).toList();
  }

  double _calculateInterval(List<FlSpot> data) {
    if (data.isEmpty) return 50;
    final maxY = data.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = data.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    if (range <= 0) return 50;
    return (range / 4).ceilToDouble();
  }

  List<String> _getMonthLabels(List<tx.Transaction> transactions) {
    if (transactions.isEmpty) return [];

    final sortedTransactions = List<tx.Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final Set<String> labels = {};
    for (final transaction in sortedTransactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      labels.add('${monthNames[date.month - 1]} ${date.day}');
    }
    return labels.toList();
  }

  Map<String, double> _getCategoryTotals(
    List<tx.Transaction> transactions,
    CategoryState categoryState,
    String type,
  ) {
    final Map<String, double> totals = {};

    for (final transaction in transactions) {
      final category = categoryState.categories.firstWhere(
        (c) => c.id == transaction.categoryId,
        orElse: () => Category(
          id: transaction.categoryId,
          name: 'Unknown',
          iconName: 'help',
          color: Colors.grey.value,
          type: 'expense',
          createdAt: 0,
        ),
      );

      if (category.type == type) {
        totals[category.id] = (totals[category.id] ?? 0) + transaction.amount;
      }
    }

    return totals;
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart,
      'directions_car': Icons.directions_car,
      'movie': Icons.movie,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'flight': Icons.flight,
      'home': Icons.home,
      'pets': Icons.pets,
      'sports_esports': Icons.sports_esports,
      'attach_money': Icons.attach_money,
      'work': Icons.work,
      'card_giftcard': Icons.card_giftcard,
      'account_balance': Icons.account_balance,
      'trending_up': Icons.trending_up,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  void _navigateToEdit(Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );
  }

  void _navigateToAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
    );
  }

  Future<void> _confirmDelete(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"?\n\n'
          'This will also delete all transactions associated with this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(accountProvider.notifier)
          .deleteAccount(account.id);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(); // Go back after deletion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${account.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = ref.read(accountProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _TransactionSummary {
  final double totalExpense;
  final double totalIncome;
  final double totalCorrection;
  final int expenseCount;
  final int incomeCount;
  final int correctionCount;

  _TransactionSummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.totalCorrection,
    required this.expenseCount,
    required this.incomeCount,
    required this.correctionCount,
  });
}
