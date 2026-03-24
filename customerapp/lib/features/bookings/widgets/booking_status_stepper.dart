import 'package:flutter/material.dart';

class BookingStatusStepper extends StatelessWidget {
  final String currentStatus;

  const BookingStatusStepper({super.key, required this.currentStatus});

  static const _steps = [
    _StepInfo(status: 'pending', label: 'Booked', icon: Icons.check_circle),
    _StepInfo(status: 'assigned', label: 'Assigned', icon: Icons.person_add),
    _StepInfo(
      status: 'worker_on_way',
      label: 'Worker on way',
      icon: Icons.directions_walk,
    ),
    _StepInfo(
      status: 'in_progress',
      label: 'In progress',
      icon: Icons.engineering,
    ),
    _StepInfo(status: 'completed', label: 'Completed', icon: Icons.task_alt),
  ];

  int get _currentIndex {
    if (currentStatus == 'cancelled') return -1;
    if (currentStatus == 'confirmed') return 1; // Same visual as assigned
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].status == currentStatus) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex;

    if (currentStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[600], size: 24),
            const SizedBox(width: 12),
            Text(
              'Booking Cancelled',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index < activeIndex;
        final isCurrent = index == activeIndex;
        final isFuture = index > activeIndex;

        return _StepRow(
          label: step.label,
          icon: step.icon,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isFuture: isFuture,
          isLast: index == _steps.length - 1,
        );
      }),
    );
  }
}

class _StepInfo {
  final String status;
  final String label;
  final IconData icon;

  const _StepInfo({
    required this.status,
    required this.label,
    required this.icon,
  });
}

class _StepRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final bool isLast;

  const _StepRow({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Vertical line + circle
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle / indicator
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent
                        ? Colors.amber[700]
                        : Colors.grey[300],
                    border: isCurrent
                        ? Border.all(color: Colors.amber[300]!, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : isCurrent
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Icon(icon, size: 14, color: Colors.grey[500]),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 24),
                      color: isCompleted ? Colors.amber[700] : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isFuture ? Colors.grey[400] : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
