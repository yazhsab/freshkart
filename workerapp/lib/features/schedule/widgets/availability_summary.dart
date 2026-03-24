import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class AvailabilitySummary extends StatelessWidget {
  final int totalSlots;
  final int bookedSlots;

  const AvailabilitySummary({
    super.key,
    required this.totalSlots,
    required this.bookedSlots,
  });

  @override
  Widget build(BuildContext context) {
    final available = totalSlots - bookedSlots;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WorkerColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
            label: 'Total',
            value: '$totalSlots',
            color: WorkerColors.primary,
          ),
          _Stat(label: 'Booked', value: '$bookedSlots', color: Colors.blue),
          _Stat(label: 'Available', value: '$available', color: Colors.green),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
