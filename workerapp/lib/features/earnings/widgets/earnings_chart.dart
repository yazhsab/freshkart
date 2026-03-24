import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/models/earnings_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class EarningsChart extends StatelessWidget {
  final List<DailyEarning> dailyEarnings;
  const EarningsChart({super.key, required this.dailyEarnings});

  @override
  Widget build(BuildContext context) {
    if (dailyEarnings.isEmpty) return const SizedBox.shrink();

    final maxY =
        dailyEarnings.map((e) => e.amount).reduce((a, b) => a > b ? a : b) *
        1.2;

    return BarChart(
      BarChartData(
        maxY: maxY > 0 ? maxY : 1000,
        barGroups: dailyEarnings.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.amount,
                color: WorkerColors.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dailyEarnings.length) {
                  return Text(
                    DateFormat('dd').format(dailyEarnings[index].date),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toInt()}\n${dailyEarnings[group.x].jobs} jobs',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}
