import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/date_util.dart';

class JobTimerWidget extends StatelessWidget {
  final Duration elapsed;
  final bool isOvertime;

  const JobTimerWidget({
    super.key,
    required this.elapsed,
    this.isOvertime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isOvertime
            ? Colors.red.shade50
            : WorkerColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOvertime
              ? Colors.red.shade200
              : WorkerColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: isOvertime ? Colors.red : WorkerColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            DateUtil.timerFormat(elapsed),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isOvertime ? Colors.red : WorkerColors.primary,
            ),
          ),
          if (isOvertime) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OVERTIME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
