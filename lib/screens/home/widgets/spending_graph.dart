import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class SpendingGraph extends ConsumerWidget {
  const SpendingGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);
    final categoryState = ref.watch(categoryProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    
    // Build a map of categoryId -> isExpense for quick lookup
    final expenseCategoryIds = <String>{};
    for (final category in categoryState.categories) {
      if (category.isExpense) {
        expenseCategoryIds.add(category.id);
      }
    }
    
    final chartData = _buildWeeklySpendingData(
      transactionState,
      expenseCategoryIds,
    );

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
          if (chartData.spots.isEmpty)
            _buildEmptyState()
          else
            SizedBox(
              height: 200,
              child: LineChart(_buildChartData(chartData, accentColor)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No spending data yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add expense transactions to see trends',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ChartData _buildWeeklySpendingData(
    TransactionState state,
    Set<String> expenseCategoryIds,
  ) {
    if (state.transactions.isEmpty) {
      return _ChartData(spots: [], labels: [], maxY: 100);
    }

    // Get last 5 weeks of expense data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weeks = <DateTime>[];
    final weeklyTotals = <double>[];

    for (int i = 4; i >= 0; i--) {
      // Calculate week start (Monday)
      final daysToSubtract = today.weekday - 1 + (i * 7);
      final weekStart = today.subtract(Duration(days: daysToSubtract));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      weeks.add(weekStart);

      // Sum expenses for this week
      double total = 0;
      for (final tx in state.transactions) {
        // Check if this transaction is an expense
        if (!expenseCategoryIds.contains(tx.categoryId)) {
          continue; // Skip income transactions
        }
        
        final txDate = DateTime.fromMillisecondsSinceEpoch(tx.date);
        final txDay = DateTime(txDate.year, txDate.month, txDate.day);
        
        if (!txDay.isBefore(weekStart) && !txDay.isAfter(weekEnd)) {
          total += tx.amount; // Amount is already positive
        }
      }
      weeklyTotals.add(total);
    }

    // Check if all zeros - no expense data
    if (weeklyTotals.every((t) => t == 0)) {
      return _ChartData(spots: [], labels: [], maxY: 100);
    }

    // Build spots and labels
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < weeks.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklyTotals[i]));
      labels.add(DateFormat('MMM d').format(weeks[i]));
    }

    // Calculate max Y with some padding
    final maxValue = weeklyTotals.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue == 0 ? 100.0 : (maxValue * 1.2).ceilToDouble();

    return _ChartData(spots: spots, labels: labels, maxY: maxY);
  }

  LineChartData _buildChartData(_ChartData data, Color accentColor) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: data.maxY / 5,
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
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) {
                return const SizedBox.shrink();
              }
              return Text(
                '\$${value.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.labels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.labels[index],
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
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
      maxX: (data.spots.length - 1).toDouble(),
      minY: 0,
      maxY: data.maxY,
      lineBarsData: [
        LineChartBarData(
          spots: data.spots,
          isCurved: true,
          color: accentColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: accentColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: accentColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  final List<FlSpot> spots;
  final List<String> labels;
  final double maxY;

  _ChartData({
    required this.spots,
    required this.labels,
    required this.maxY,
  });
}
