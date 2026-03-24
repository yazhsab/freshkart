import 'package:flutter/material.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/utils/date_util.dart';

/// Vertical order‐status stepper showing progression through:
/// Placed -> Confirmed -> Packing -> Picked Up -> Delivered.
class OrderStatusStepper extends StatelessWidget {
  final String currentStatus;
  final DateTime? placedAt;
  final DateTime? confirmedAt;
  final DateTime? packedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const OrderStatusStepper({
    super.key,
    required this.currentStatus,
    this.placedAt,
    this.confirmedAt,
    this.packedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  // The canonical order of statuses.
  static const _statuses = [
    'pending',
    'confirmed',
    'packing',
    'picked_up',
    'delivered',
  ];

  static const _labels = [
    'Placed',
    'Confirmed',
    'Packing',
    'Picked Up',
    'Delivered',
  ];

  int get _currentIndex {
    final idx = _statuses.indexOf(currentStatus);
    // cancelled => treat as stopped at whatever last step completed
    return idx >= 0 ? idx : 0;
  }

  DateTime? _timestampFor(int index) {
    switch (index) {
      case 0:
        return placedAt;
      case 1:
        return confirmedAt;
      case 2:
        return packedAt;
      case 3:
        return pickedUpAt;
      case 4:
        return deliveredAt;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = currentStatus == 'cancelled';

    return Column(
      children: List.generate(_statuses.length, (index) {
        final isCompleted =
            index < _currentIndex ||
            (index == _currentIndex && currentStatus == 'delivered');
        final isCurrent = index == _currentIndex && !isCancelled;
        final isFuture = index > _currentIndex;
        final isLast = index == _statuses.length - 1;

        return _StepRow(
          label: _labels[index],
          timestamp: _timestampFor(index),
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isFuture: isFuture,
          isLast: isLast,
          isCancelled: isCancelled && index == _currentIndex,
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual step row
// ---------------------------------------------------------------------------

class _StepRow extends StatelessWidget {
  final String label;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final bool isLast;
  final bool isCancelled;

  const _StepRow({
    required this.label,
    this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.isLast,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: dot + connector line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _dot(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.primaryGreen
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right column: label + timestamp
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCompleted || isCurrent
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isFuture
                          ? AppColors.textHint
                          : isCancelled
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateUtil.formatOrderDate(timestamp!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    if (isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryGreen,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }

    if (isCurrent) {
      return _PulsingDot(
        color: isCancelled ? AppColors.error : AppColors.primaryGreen,
      );
    }

    // Future
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing green dot for current step
// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 1.0 + _ctrl.value * 0.3;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4 * _ctrl.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
