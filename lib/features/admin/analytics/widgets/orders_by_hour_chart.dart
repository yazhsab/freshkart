import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../analytics_provider.dart';

class OrdersByHourChart extends StatelessWidget {
  const OrdersByHourChart({super.key, required this.data});

  final List<HourlyOrders> data;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        data.fold<int>(0, (m, e) => e.count > m ? e.count : m).toDouble();
    final interval = maxCount > 0 ? (maxCount / 4).ceilToDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Orders by Hour',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount > 0 ? maxCount * 1.2 : 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hour = group.x;
                      final label =
                          '${hour.toString().padLeft(2, '0')}:00 - ${data[hour].count} orders';
                      return BarTooltipItem(
                        label,
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        // Show every 3 hours
                        if (hour % 3 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: interval > 0 ? interval : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval > 0 ? interval : 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.map((h) {
                  return BarChartGroupData(
                    x: h.hour,
                    barRods: [
                      BarChartRodData(
                        toY: h.count.toDouble(),
                        width: 8,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxCount > 0 ? maxCount * 1.2 : 10,
                          color: AppColors.primary.withValues(alpha: 0.04),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
