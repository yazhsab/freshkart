import 'package:flutter/material.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/date_util.dart';
import 'package:freshkart_vendor/core/models/order_model.dart';

class OrderStatusTimeline extends StatefulWidget {
  final OrderModel order;

  const OrderStatusTimeline({super.key, required this.order});

  @override
  State<OrderStatusTimeline> createState() => _OrderStatusTimelineState();
}

class _OrderStatusTimelineState extends State<OrderStatusTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepRow(steps[i], isLast: i == steps.length - 1),
        ],
      ],
    );
  }

  List<_TimelineStep> _buildSteps() {
    final order = widget.order;
    final statusIndex = _statusIndex(order.status);

    return [
      _TimelineStep(
        label: 'Order Placed',
        icon: Icons.receipt_long_rounded,
        timestamp: order.createdAt,
        state: statusIndex >= 0 ? _StepState.completed : _StepState.future,
      ),
      _TimelineStep(
        label: 'Confirmed',
        icon: Icons.check_circle_outline_rounded,
        timestamp: order.vendorConfirmedAt,
        state: statusIndex > 0
            ? _StepState.completed
            : statusIndex == 0 && order.isPending
            ? _StepState.future
            : statusIndex == 1
            ? _StepState.current
            : _StepState.future,
      ),
      _TimelineStep(
        label: 'Packing',
        icon: Icons.inventory_2_outlined,
        timestamp:
            order.vendorConfirmedAt != null &&
                order.packedAt == null &&
                order.isPacking
            ? null
            : order.packedAt,
        state: statusIndex > 2
            ? _StepState.completed
            : statusIndex == 2
            ? _StepState.current
            : _StepState.future,
      ),
      _TimelineStep(
        label: 'Ready for Pickup',
        icon: Icons.local_shipping_outlined,
        timestamp: order.packedAt,
        state: statusIndex > 3
            ? _StepState.completed
            : statusIndex == 3
            ? _StepState.current
            : _StepState.future,
      ),
      _TimelineStep(
        label: 'Picked Up',
        icon: Icons.delivery_dining_rounded,
        timestamp: order.pickedUpAt,
        state: statusIndex > 4
            ? _StepState.completed
            : statusIndex == 4
            ? _StepState.current
            : _StepState.future,
      ),
      _TimelineStep(
        label: order.isCancelled ? 'Cancelled' : 'Delivered',
        icon: order.isCancelled
            ? Icons.cancel_outlined
            : Icons.check_circle_rounded,
        timestamp: order.isCancelled ? order.cancelledAt : order.deliveredAt,
        state: order.isDelivered || order.isCancelled
            ? _StepState.completed
            : _StepState.future,
        isCancelled: order.isCancelled,
      ),
    ];
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'packing':
        return 2;
      case 'ready':
        return 3;
      case 'picked_up':
        return 4;
      case 'delivered':
        return 5;
      case 'cancelled':
        return 5;
      default:
        return -1;
    }
  }

  Widget _buildStepRow(_TimelineStep step, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _buildIndicator(step),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.state == _StepState.completed
                          ? VendorColors.primary
                          : VendorColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: step.state == _StepState.current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: step.state == _StepState.future
                          ? VendorColors.textHint
                          : step.isCancelled
                          ? VendorColors.cancelledOrder
                          : VendorColors.textPrimary,
                    ),
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateUtil.formatDateTime(step.timestamp!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: VendorColors.textSecondary,
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

  Widget _buildIndicator(_TimelineStep step) {
    if (step.state == _StepState.completed) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: step.isCancelled
              ? VendorColors.cancelledOrder
              : VendorColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          step.isCancelled ? Icons.close_rounded : Icons.check_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    if (step.state == _StepState.current) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: VendorColors.primary.withValues(
                alpha: _pulseAnimation.value * 0.2,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: VendorColors.primary, width: 2),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: VendorColors.primary.withValues(
                    alpha: _pulseAnimation.value,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    }

    // Future state
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: VendorColors.fieldBackground,
        shape: BoxShape.circle,
        border: Border.all(color: VendorColors.divider, width: 2),
      ),
      child: Icon(step.icon, size: 12, color: VendorColors.textHint),
    );
  }
}

enum _StepState { completed, current, future }

class _TimelineStep {
  final String label;
  final IconData icon;
  final DateTime? timestamp;
  final _StepState state;
  final bool isCancelled;

  const _TimelineStep({
    required this.label,
    required this.icon,
    this.timestamp,
    required this.state,
    this.isCancelled = false,
  });
}
