import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/features/earnings/providers/earnings_provider.dart';

class EarningsChart extends StatelessWidget {
  final List<DailyRevenuePoint> dailyRevenue;
  final String period;

  const EarningsChart({
    super.key,
    required this.dailyRevenue,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyRevenue.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No revenue data available',
            style: TextStyle(color: VendorColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final maxY = dailyRevenue
        .map((e) => e.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final roundedMaxY = maxY == 0 ? 1000.0 : (maxY * 1.2);

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: roundedMaxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: VendorColors.divider,
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: roundedMaxY / 4,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        CurrencyUtil.formatCompact(value),
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
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= dailyRevenue.length) {
                      return const SizedBox.shrink();
                    }

                    // Show fewer labels to avoid overlap
                    final totalPoints = dailyRevenue.length;
                    final showEvery = totalPoints <= 7 ? 1 : (totalPoints ~/ 6);
                    if (index % showEvery != 0 && index != totalPoints - 1) {
                      return const SizedBox.shrink();
                    }

                    final date = dailyRevenue[index].date;
                    final label = _xAxisLabel(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: VendorColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (dailyRevenue.length - 1).toDouble(),
            minY: 0,
            maxY: roundedMaxY,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => VendorColors.primaryDark,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final date = dailyRevenue[index].date;
                    final dateStr = DateFormat('dd MMM').format(date);
                    return LineTooltipItem(
                      '$dateStr\n${CurrencyUtil.formatPrice(spot.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((_) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: VendorColors.primary.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: VendorColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                  );
                }).toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  dailyRevenue.length,
                  (i) => FlSpot(i.toDouble(), dailyRevenue[i].amount),
                ),
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: VendorColors.primary,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: dailyRevenue.length <= 7,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: VendorColors.primary,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      VendorColors.primary.withValues(alpha: 0.3),
                      VendorColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  String _xAxisLabel(DateTime date) {
    switch (period) {
      case 'today':
        return DateFormat('ha').format(date).toLowerCase();
      case 'week':
        return DateFormat('EEE').format(date);
      case 'month':
        return DateFormat('dd').format(date);
      default:
        return DateFormat('dd').format(date);
    }
  }
}
