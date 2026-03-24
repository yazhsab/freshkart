import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/features/dashboard/providers/dashboard_provider.dart';

class EarningsCard extends StatelessWidget {
  final List<DailyRevenue> dailyRevenues;

  const EarningsCard({super.key, required this.dailyRevenues});

  double get _total => dailyRevenues.fold(0.0, (sum, d) => sum + d.amount);

  double get _maxY {
    final maxVal = dailyRevenues.fold(
      0.0,
      (m, d) => d.amount > m ? d.amount : m,
    );
    return maxVal > 0 ? maxVal * 1.3 : 100;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "This Week's Earnings",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
              Text(
                '${VendorAppConfig.currency}${_total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: VendorColors.earningsGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${VendorAppConfig.currency}${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                              fontSize: 10,
                              color: VendorColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dailyRevenues.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat(
                              'E',
                            ).format(dailyRevenues[index].date).substring(0, 2),
                            style: const TextStyle(
                              fontSize: 11,
                              color: VendorColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _maxY / 3,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: VendorColors.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dailyRevenues.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyRevenues[i].amount,
                        color: VendorColors.primaryLight,
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
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
