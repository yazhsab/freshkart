import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/models/earnings_model.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';

class DailyChart extends StatelessWidget {
  final List<DailyEarnings> dailyEarnings;
  final double bonusPortionPercent;

  const DailyChart({
    super.key,
    required this.dailyEarnings,
    this.bonusPortionPercent = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyEarnings.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No earnings data',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: DeliveryColors.textSecondary,
          ),
        ),
      );
    }

    final maxAmount = dailyEarnings
        .map((e) => e.earnings)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxAmount > 0 ? (maxAmount * 1.3).ceilToDouble() : 100.0;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => DeliveryColors.primaryDark,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final earning = dailyEarnings[group.x.toInt()];
                final dayName = _getDayName(earning.date);
                return BarTooltipItem(
                  '${CurrencyUtil.format(earning.earnings)} on $dayName',
                  GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyEarnings.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getDayName(dailyEarnings[index].date),
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      CurrencyUtil.formatCompact(value),
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                  );
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: DeliveryColors.divider,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyEarnings.asMap().entries.map((entry) {
            final index = entry.key;
            final earning = entry.value;
            final bonusPortion = earning.earnings * bonusPortionPercent;
            final basePortion = earning.earnings - bonusPortion;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: earning.earnings,
                  width: dailyEarnings.length <= 7 ? 22 : 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  rodStackItems: [
                    BarChartRodStackItem(
                      0,
                      basePortion,
                      DeliveryColors.earningsTeal,
                    ),
                    BarChartRodStackItem(
                      basePortion,
                      earning.earnings,
                      DeliveryColors.bonusGold,
                    ),
                  ],
                  color: DeliveryColors.earningsTeal,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return dayNames[date.weekday - 1];
    } catch (_) {
      return dateStr.length > 3 ? dateStr.substring(0, 3) : dateStr;
    }
  }
}
