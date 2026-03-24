import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';

class DeliveryTimeline extends StatelessWidget {
  final DeliveryPhase currentPhase;
  final DateTime? assignedAt;
  final DateTime? reachedVendorAt;
  final DateTime? pickedUpAt;
  final DateTime? reachedCustomerAt;
  final DateTime? deliveredAt;

  const DeliveryTimeline({
    super.key,
    required this.currentPhase,
    this.assignedAt,
    this.reachedVendorAt,
    this.pickedUpAt,
    this.reachedCustomerAt,
    this.deliveredAt,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'Order Accepted',
        timestamp: assignedAt,
        status: _getStepStatus(0),
      ),
      _TimelineStep(
        title: 'Reached Vendor',
        timestamp: reachedVendorAt,
        status: _getStepStatus(1),
      ),
      _TimelineStep(
        title: 'Pickup Confirmed',
        timestamp: pickedUpAt,
        status: _getStepStatus(2),
      ),
      _TimelineStep(
        title: 'Reached Customer',
        timestamp: reachedCustomerAt,
        status: _getStepStatus(3),
      ),
      _TimelineStep(
        title: 'Delivered',
        timestamp: deliveredAt,
        status: _getStepStatus(4),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            return _TimelineStepWidget(step: step, isLast: isLast);
          }),
        ],
      ),
    );
  }

  _StepStatus _getStepStatus(int stepIndex) {
    int currentIndex;
    switch (currentPhase) {
      case DeliveryPhase.goingToVendor:
        currentIndex = 0;
        break;
      case DeliveryPhase.pickupOtp:
        currentIndex = 1;
        break;
      case DeliveryPhase.goingToCustomer:
        currentIndex = 2;
        break;
      case DeliveryPhase.deliveryOtp:
        currentIndex = 3;
        break;
      case DeliveryPhase.completed:
        currentIndex = 4;
        break;
    }

    if (stepIndex < currentIndex) return _StepStatus.completed;
    if (stepIndex == currentIndex) return _StepStatus.current;
    return _StepStatus.upcoming;
  }
}

enum _StepStatus { completed, current, upcoming }

class _TimelineStep {
  final String title;
  final DateTime? timestamp;
  final _StepStatus status;

  _TimelineStep({required this.title, this.timestamp, required this.status});
}

class _TimelineStepWidget extends StatefulWidget {
  final _TimelineStep step;
  final bool isLast;

  const _TimelineStepWidget({required this.step, required this.isLast});

  @override
  State<_TimelineStepWidget> createState() => _TimelineStepWidgetState();
}

class _TimelineStepWidgetState extends State<_TimelineStepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.step.status == _StepStatus.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TimelineStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step.status == _StepStatus.current) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _buildDot(),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: widget.step.status == _StepStatus.completed
                          ? DeliveryColors.stepDone
                          : DeliveryColors.divider,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.step.title,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: widget.step.status == _StepStatus.current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.step.status == _StepStatus.upcoming
                          ? DeliveryColors.textSecondary
                          : DeliveryColors.textPrimary,
                    ),
                  ),
                  if (widget.step.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateUtil.formatTime(widget.step.timestamp!),
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                  ],
                  if (widget.step.status == _StepStatus.current &&
                      widget.step.timestamp == null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'In progress...',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: DeliveryColors.primary,
                        fontStyle: FontStyle.italic,
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

  Widget _buildDot() {
    switch (widget.step.status) {
      case _StepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: DeliveryColors.stepDone,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        );

      case _StepStatus.current:
        return _PulseAnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: DeliveryColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DeliveryColors.primary.withOpacity(
                      0.3 + _pulseController.value * 0.3,
                    ),
                    blurRadius: 4 + _pulseController.value * 6,
                    spreadRadius: _pulseController.value * 2,
                  ),
                ],
              ),
              child: const Icon(Icons.circle, size: 10, color: Colors.white),
            );
          },
        );

      case _StepStatus.upcoming:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: DeliveryColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: DeliveryColors.divider, width: 2),
          ),
        );
    }
  }
}

class _PulseAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _PulseAnimatedBuilder({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
