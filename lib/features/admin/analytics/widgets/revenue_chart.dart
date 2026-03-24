import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../analytics_provider.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({
    super.key,
    required this.groceryData,
    required this.serviceData,
  });

  final List<DailyRevenue> groceryData;
  final List<DailyRevenue> serviceData;

  @override
  Widget build(BuildContext context) {
    if (groceryData.isEmpty && serviceData.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text('No revenue data for this period',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Merge all dates and build combined series
    final allDates = <DateTime>{
      ...groceryData.map((d) => d.date),
      ...serviceData.map((d) => d.date),
    }.toList()
      ..sort();

    final groceryMap = {for (final d in groceryData) d.date: d.amount};
    final serviceMap = {for (final d in serviceData) d.date: d.amount};

    final grocerySpots = <FlSpot>[];
    final serviceSpots = <FlSpot>[];
    final combinedSpots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < allDates.length; i++) {
      final g = groceryMap[allDates[i]] ?? 0;
      final s = serviceMap[allDates[i]] ?? 0;
      final c = g + s;
      grocerySpots.add(FlSpot(i.toDouble(), g));
      serviceSpots.add(FlSpot(i.toDouble(), s));
      combinedSpots.add(FlSpot(i.toDouble(), c));
      if (c > maxY) maxY = c;
    }

    if (maxY == 0) maxY = 1000;
    final interval = (maxY / 4).ceilToDouble();

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
          Row(
            children: [
              const Text('Daily Revenue (GMV)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              _LegendDot(color: AppColors.primary, label: 'Grocery'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.secondary, label: 'Services'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  label: 'Combined'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: allDates.length > 10
                          ? (allDates.length / 6).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= allDates.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM').format(allDates[idx]),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value >= 100000) {
                          return Text(
                            '\u20B9${(value / 100000).toStringAsFixed(1)}L',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          );
                        }
                        if (value >= 1000) {
                          return Text(
                            '\u20B9${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          );
                        }
                        return Text(
                          '\u20B9${value.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (allDates.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: maxY * 1.1,
                lineBarsData: [
                  // Combined (area fill)
                  LineChartBarData(
                    spots: combinedSpots,
                    isCurved: true,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    barWidth: 0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.07),
                    ),
                  ),
                  // Grocery
                  LineChartBarData(
                    spots: grocerySpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: allDates.length <= 15,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  // Services
                  LineChartBarData(
                    spots: serviceSpots,
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: allDates.length <= 15,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.secondary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final color = s.bar.color ?? Colors.white;
                        return LineTooltipItem(
                          '\u20B9${s.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
