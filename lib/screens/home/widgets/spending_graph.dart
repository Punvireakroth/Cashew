import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpendingGraph extends StatelessWidget {
  const SpendingGraph({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: LineChart(_buildChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
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
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const dates = ['Oct 25', 'Nov 2', 'Nov 10', 'Nov 17', 'Nov 25'];
              if (value.toInt() >= 0 && value.toInt() < dates.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dates[value.toInt()],
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
    );
  }
}

