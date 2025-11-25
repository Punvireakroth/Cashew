import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
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
  Timer? _debounce;

  // Filter state
  DateTimeRange? _dateRange;
  List<String> _selectedCategoryIds = [];
  String? _selectedType; // 'income', 'expense', or null (all)

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransactions(refresh: true);
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(transactionProvider.notifier).loadMoreTransactions();
    }
  }

  void _onSearchChanged() {
    // Debounce search
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      ref.read(transactionProvider.notifier).setSearchQuery(
            query.isEmpty ? null : query,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final hasFilters = transactionState.filters.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
              ),
              if (hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(transactionProvider.notifier)
              .loadTransactions(refresh: true);
        },
        child: _buildBody(transactionState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TransactionFormScreen(),
            ),
          );
          if (result == true && mounted) {
            // Transaction was added, refresh list
            ref.read(transactionProvider.notifier)
                .loadTransactions(refresh: true);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildBody(TransactionState state) {
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
              'Error loading transactions',
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
              onPressed: () {
                ref.read(transactionProvider.notifier)
                    .loadTransactions(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        message: state.filters.hasActiveFilters
            ? 'No transactions found'
            : 'No transactions yet',
        actionText: state.filters.hasActiveFilters ? 'Clear Filters' : 'Add Transaction',
        onAction: state.filters.hasActiveFilters
            ? () {
                _searchController.clear();
                _selectedCategoryIds.clear();
                _dateRange = null;
                _selectedType = null;
                ref.read(transactionProvider.notifier).clearFilters();
              }
            : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen(),
                  ),
                );
                if (result == true && mounted) {
                  ref.read(transactionProvider.notifier)
                      .loadTransactions(refresh: true);
                }
              },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          // Loading indicator at bottom
          return state.isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final transaction = state.transactions[index];
        return TransactionItem(
          transaction: transaction,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionFormScreen(
                  transaction: transaction,
                ),
              ),
            );
            if (result == true && mounted) {
              ref.read(transactionProvider.notifier)
                  .loadTransactions(refresh: true);
            }
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        dateRange: _dateRange,
        selectedCategoryIds: _selectedCategoryIds,
        selectedType: _selectedType,
        onApply: (dateRange, categoryIds, type) {
          setState(() {
            _dateRange = dateRange;
            _selectedCategoryIds = categoryIds ?? [];
            _selectedType = type;
          });

          // Apply filters
          ref.read(transactionProvider.notifier).setDateRange(
                dateRange?.start,
                dateRange?.end,
              );
          ref.read(transactionProvider.notifier)
              .setCategoryFilter(categoryIds);
          ref.read(transactionProvider.notifier).setTypeFilter(type);
        },
        onReset: () {
          setState(() {
            _dateRange = null;
            _selectedCategoryIds.clear();
            _selectedType = null;
          });

          // Clear filters
          ref.read(transactionProvider.notifier).clearFilters();
        },
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;
  final List<String> selectedCategoryIds;
  final String? selectedType;
  final Function(DateTimeRange?, List<String>?, String?) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.dateRange,
    required this.selectedCategoryIds,
    required this.selectedType,
    required this.onApply,
    required this.onReset,
  });

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late DateTimeRange? _dateRange;
  late List<String> _selectedCategoryIds;
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange;
    _selectedCategoryIds = List.from(widget.selectedCategoryIds);
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
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
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
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
                  // Date Range Filter
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('This Month'),
                        selected: _isThisMonth(),
                        onSelected: (_) => _selectThisMonth(),
                      ),
                      FilterChip(
                        label: const Text('Last Month'),
                        selected: _isLastMonth(),
                        onSelected: (_) => _selectLastMonth(),
                      ),
                      FilterChip(
                        label: const Text('Custom'),
                        selected: _dateRange != null &&
                            !_isThisMonth() &&
                            !_isLastMonth(),
                        onSelected: (_) => _selectCustomDateRange(),
                      ),
                      if (_dateRange != null)
                        ActionChip(
                          label: const Text('Clear'),
                          onPressed: () {
                            setState(() {
                              _dateRange = null;
                            });
                          },
                        ),
                    ],
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_dateRange!.end)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Transaction Type Filter
                  const Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedType == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedType = null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: _selectedType == 'income',
                        onSelected: (_) {
                          setState(() {
                            _selectedType = 'income';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: _selectedType == 'expense',
                        onSelected: (_) {
                          setState(() {
                            _selectedType = 'expense';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Filter
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (categoryState.categories.isEmpty)
                    Text(
                      'No categories available',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryState.categories.map((category) {
                        final isSelected = _selectedCategoryIds.contains(category.id);
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
                    _dateRange,
                    _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
                    _selectedType,
                  );
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isThisMonth() {
    if (_dateRange == null) return false;
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
    return _dateRange!.start.isAtSameMomentAs(thisMonthStart) &&
        _dateRange!.end.isAtSameMomentAs(thisMonthEnd);
  }

  bool _isLastMonth() {
    if (_dateRange == null) return false;
    final now = DateTime.now();
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    return _dateRange!.start.isAtSameMomentAs(lastMonthStart) &&
        _dateRange!.end.isAtSameMomentAs(lastMonthEnd);
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      );
    });
  }

  void _selectLastMonth() {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0),
      );
    });
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
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

