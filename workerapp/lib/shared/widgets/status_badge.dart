import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isBgv;

  const StatusBadge({super.key, required this.status, this.isBgv = false});

  @override
  Widget build(BuildContext context) {
    final color = isBgv
        ? WorkerColors.bgvColor(status)
        : WorkerColors.statusColor(status);
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
