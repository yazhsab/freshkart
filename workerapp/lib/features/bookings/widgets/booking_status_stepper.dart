import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class BookingStatusStepper extends StatelessWidget {
  final String status;
  const BookingStatusStepper({super.key, required this.status});

  static const _steps = [
    'assigned',
    'confirmed',
    'on_way',
    'in_progress',
    'completed',
  ];
  static const _labels = [
    'Assigned',
    'Confirmed',
    'On Way',
    'In Progress',
    'Completed',
  ];

  int get _currentStep {
    final idx = _steps.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled' || status == 'disputed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                color: stepIndex < _currentStep
                    ? WorkerColors.primary
                    : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isComplete = stepIndex <= _currentStep;
          final isCurrent = stepIndex == _currentStep;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? WorkerColors.primary
                      : Colors.grey.shade300,
                  border: isCurrent
                      ? Border.all(color: WorkerColors.primary, width: 3)
                      : null,
                ),
                child: isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                _labels[stepIndex],
                style: TextStyle(
                  fontSize: 9,
                  color: isComplete ? WorkerColors.primary : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
