import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency.dart';
import '../analytics_provider.dart';

class TopVendorsChart extends StatelessWidget {
  const TopVendorsChart({super.key, required this.data});

  final List<TopVendor> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No vendor revenue data',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final maxRevenue = data.fold<double>(0, (m, e) => e.revenue > m ? e.revenue : m);

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
          const Text('Top 5 Vendors by Revenue',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: data.length * 48.0 + 24,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRevenue * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final vendor = data[group.x];
                      return BarTooltipItem(
                        '${vendor.name}\n${formatINR(vendor.revenue)} (${vendor.orders} orders)',
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            formatINRCompact(data[idx].revenue),
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
                      reservedSize: 100,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return SizedBox(
                          width: 96,
                          child: Text(
                            data[idx].name,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: false,
                  drawVerticalLine: true,
                  getDrawingVerticalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].revenue,
                        width: 20,
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
