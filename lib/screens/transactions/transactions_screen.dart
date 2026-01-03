import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/empty_state.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _monthScrollController = ScrollController();
  Timer? _debounce;

  // Selected month
  late DateTime _selectedMonth;
  late List<DateTime> _availableMonths;

  // Filter state
  List<String> _selectedCategoryIds = [];
  String? _selectedType;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Initialize with current month
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);

    // Generate available months (12 months back to 1 month forward)
    _availableMonths = _generateAvailableMonths();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
      _loadTransactionsForMonth();
      _scrollToSelectedMonth();
    });
  }

  List<DateTime> _generateAvailableMonths() {
    final now = DateTime.now();
    final months = <DateTime>[];

    // 12 months back
    for (int i = 12; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }
    // 1 month forward
    months.add(DateTime(now.year, now.month + 1, 1));

    return months;
  }

  void _scrollToSelectedMonth() {
    final index = _availableMonths.indexWhere(
      (month) =>
          month.year == _selectedMonth.year &&
          month.month == _selectedMonth.month,
    );
    if (index != -1 && _monthScrollController.hasClients) {
      final offset =
          index * 100.0 - (MediaQuery.of(context).size.width / 2) + 50;
      _monthScrollController.animateTo(
        offset.clamp(0.0, _monthScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _loadTransactionsForMonth() {
    final startDate = _selectedMonth;
    final endDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    ref.read(transactionProvider.notifier).setDateRange(startDate, endDate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _monthScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionProvider.notifier).loadMoreTransactions();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      ref
          .read(transactionProvider.notifier)
          .setSearchQuery(query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final categoryState = ref.watch(categoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.transactions,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (collapsible)
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchTransactions,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

          // Month Tabs
          _buildMonthTabs(),

          // Summary Section
          _buildSummarySection(transactionState, categoryState),

          // Transaction List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadTransactionsForMonth();
              },
              child: _buildBody(transactionState, categoryState, l10n),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          );
          if (result == true && mounted) {
            _loadTransactionsForMonth();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthTabs() {
    return Container(
      height: 50,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _availableMonths.length,
        itemBuilder: (context, index) {
          final month = _availableMonths[index];
          final isSelected =
              month.year == _selectedMonth.year &&
              month.month == _selectedMonth.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = month;
              });
              _loadTransactionsForMonth();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : Colors.transparent,
                border: isSelected
                    ? Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
              ),
              child: Text(
                DateFormat('MMMM').format(month),
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(
    TransactionState transactionState,
    CategoryState categoryState,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactionState.transactions) {
      final category = categoryState.categories
          .where((cat) => cat.id == transaction.categoryId)
          .firstOrNull;

      if (category != null) {
        if (category.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }
    }

    final balance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Expense
          _buildSummaryItem(
            icon: Icons.arrow_drop_down,
            color: Colors.red[700]!,
            amount: totalExpense,
            prefix: '-',
          ),
          // Divider
          Container(width: 1, height: 30, color: Colors.grey[300]),
          // Income
          _buildSummaryItem(
            icon: Icons.arrow_drop_up,
            color: Colors.green,
            amount: totalIncome,
            prefix: '+',
          ),
          // Divider
          Container(width: 1, height: 30, color: Colors.grey[300]),
          // Balance
          _buildSummaryItem(
            icon: null,
            color: balance >= 0 ? Colors.green : Colors.red[700]!,
            amount: balance.abs(),
            prefix: balance >= 0 ? '= ' : '= -',
            showSign: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    IconData? icon,
    required Color color,
    required double amount,
    required String prefix,
    bool showSign = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSign && icon != null) Icon(icon, color: color, size: 20),
        Text(
          '$prefix\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(TransactionState state, CategoryState categoryState, AppLocalizations l10n) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingTransactions,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadTransactionsForMonth,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        message: state.filters.hasActiveFilters
            ? l10n.noTransactionsFound
            : l10n.noTransactionsFor(DateFormat('MMMM yyyy').format(_selectedMonth)),
        actionText: l10n.addTransaction,
        onAction: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          );
          if (result == true && mounted) {
            _loadTransactionsForMonth();
          }
        },
      );
    }

    // Group transactions by day
    final groupedTransactions = _groupTransactionsByDay(
      state.transactions,
      categoryState.categories,
    );

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedTransactions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedTransactions.length) {
          return state.isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final group = groupedTransactions[index];
        return _buildDaySection(group, categoryState.categories, l10n);
      },
    );
  }

  List<_DayGroup> _groupTransactionsByDay(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final Map<String, _DayGroup> groups = {};

    for (final transaction in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);
      final dayKey = DateFormat('yyyy-MM-dd').format(date);

      if (!groups.containsKey(dayKey)) {
        groups[dayKey] = _DayGroup(date: date, transactions: []);
      }
      groups[dayKey]!.transactions.add(transaction);
    }

    // Sort by date descending
    final sortedGroups = groups.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals for each group
    for (final group in sortedGroups) {
      double dayTotal = 0;
      for (final transaction in group.transactions) {
        final category = categories
            .where((cat) => cat.id == transaction.categoryId)
            .firstOrNull;

        if (category != null) {
          if (category.isIncome) {
            dayTotal += transaction.amount;
          } else {
            dayTotal -= transaction.amount;
          }
        }
      }
      group.total = dayTotal;
    }

    return sortedGroups;
  }

  Widget _buildDaySection(_DayGroup group, List<Category> categories, AppLocalizations l10n) {
    final isToday = _isToday(group.date);
    final isYesterday = _isYesterday(group.date);

    String dateLabel;
    if (isToday) {
      dateLabel = l10n.today;
    } else if (isYesterday) {
      dateLabel = l10n.yesterday;
    } else {
      dateLabel = DateFormat('EEEE, MMMM d').format(group.date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${group.total >= 0 ? '' : '-'}\$${group.total.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: group.total >= 0 ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Transactions for this day
        ...group.transactions.map((transaction) {
          return TransactionItem(
            transaction: transaction,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionFormScreen(transaction: transaction),
                ),
              );
              if (result == true && mounted) {
                _loadTransactionsForMonth();
              }
            },
          );
        }),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        selectedCategoryIds: _selectedCategoryIds,
        selectedType: _selectedType,
        onApply: (categoryIds, type) {
          setState(() {
            _selectedCategoryIds = categoryIds ?? [];
            _selectedType = type;
          });

          ref.read(transactionProvider.notifier).setCategoryFilter(categoryIds);
          ref.read(transactionProvider.notifier).setTypeFilter(type);
        },
        onReset: () {
          setState(() {
            _selectedCategoryIds.clear();
            _selectedType = null;
          });

          ref.read(transactionProvider.notifier).setCategoryFilter(null);
          ref.read(transactionProvider.notifier).setTypeFilter(null);
        },
      ),
    );
  }
}

/// Helper class to group transactions by day
class _DayGroup {
  final DateTime date;
  final List<Transaction> transactions;
  double total = 0;

  _DayGroup({required this.date, required this.transactions});
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final List<String> selectedCategoryIds;
  final String? selectedType;
  final Function(List<String>?, String?) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.selectedCategoryIds,
    required this.selectedType,
    required this.onApply,
    required this.onReset,
  });

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late List<String> _selectedCategoryIds;
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = List.from(widget.selectedCategoryIds);
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.filterTransactions,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: Text(l10n.reset),
                  ),
                ],
              ),
            ),

            // Filter content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Transaction Type Filter
                  Text(
                    l10n.transactionType,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.all),
                        selected: _selectedType == null,
                        onSelected: (_) {
                          setState(() => _selectedType = null);
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.income),
                        selected: _selectedType == 'income',
                        onSelected: (_) {
                          setState(() => _selectedType = 'income');
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.expense),
                        selected: _selectedType == 'expense',
                        onSelected: (_) {
                          setState(() => _selectedType = 'expense');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Filter
                  Text(
                    l10n.categories,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (categoryState.categories.isEmpty)
                    Text(
                      l10n.noCategoriesAvailable,
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryState.categories.map((category) {
                        final isSelected = _selectedCategoryIds.contains(
                          category.id,
                        );
                        return FilterChip(
                          label: Text(category.name),
                          avatar: Icon(
                            _getIconData(category.iconName),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : Color(category.color),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategoryIds.add(category.id);
                              } else {
                                _selectedCategoryIds.remove(category.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  widget.onApply(
                    _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
                    _selectedType,
                  );
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l10n.applyFilters),
              ),
            ),
          ],
        );
      },
    );
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
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
