import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency.dart';
import '../analytics_provider.dart';

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({super.key, required this.data});

  final List<CategoryShare> data;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touchedIndex = -1;

  static const _colors = [
    Color(0xFF2E7D32),
    Color(0xFFFF8F00),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFD32F2F),
    Color(0xFF00838F),
    Color(0xFF4E342E),
    Color(0xFF37474F),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No service booking data',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final total = widget.data.fold<int>(0, (s, e) => s + e.count);

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
          const Text('Service Categories',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex = response
                                .touchedSection!.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: List.generate(widget.data.length, (i) {
                      final isTouched = i == _touchedIndex;
                      final pct =
                          total > 0 ? (widget.data[i].count / total * 100) : 0;
                      return PieChartSectionData(
                        color: _colors[i % _colors.length],
                        value: widget.data[i].count.toDouble(),
                        title: isTouched
                            ? '${pct.toStringAsFixed(1)}%'
                            : '',
                        radius: isTouched ? 40 : 32,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(widget.data.length, (i) {
                    final cat = widget.data[i];
                    final pct = total > 0
                        ? (cat.count / total * 100).toStringAsFixed(1)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _colors[i % _colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${cat.count} ($pct%)',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          if (widget.data.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            ...widget.data.take(5).map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.name,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary)),
                      ),
                      Text(formatINRCompact(c.revenue),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
