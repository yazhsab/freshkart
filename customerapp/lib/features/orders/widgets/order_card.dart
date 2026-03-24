import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/models/order_model.dart';
import 'package:freshkart_customer/core/router/route_names.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/utils/currency_util.dart';
import 'package:freshkart_customer/core/utils/date_util.dart';
import 'package:freshkart_customer/features/orders/providers/orders_provider.dart';

class OrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isActive;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.isActive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isActive
            ? _activeLayout(context, ref)
            : _pastLayout(context, ref),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active order layout
  // ---------------------------------------------------------------------------

  Widget _activeLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: order# + timeago
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.orderNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              DateUtil.timeAgo(order.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Vendor name + item count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (order.vendor != null)
              Text(
                order.vendor!.shopName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Animated status badge + amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AnimatedStatusBadge(status: order.status),
            Text(
              CurrencyUtil.formatPrice(order.finalAmount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress bar
        _OrderProgressBar(status: order.status),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            if (_isTrackable(order.status))
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text(
                      'Track',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.pushNamed(
                      RouteNames.orderTracking,
                      pathParameters: {'orderId': order.id},
                    ),
                  ),
                ),
              ),
            if (_isTrackable(order.status)) const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 36,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onTap,
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Past order layout
  // ---------------------------------------------------------------------------

  Widget _pastLayout(BuildContext context, WidgetRef ref) {
    final isDelivered = order.status == 'delivered';
    final statusColor = isDelivered
        ? AppColors.statusDelivered
        : AppColors.statusCancelled;
    final statusLabel = isDelivered ? 'Delivered' : 'Cancelled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: order# + date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.orderNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              DateUtil.formatDate(order.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Vendor name
        if (order.vendor != null)
          Text(
            order.vendor!.shopName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        const SizedBox(height: 8),

        // Status + amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            Text(
              CurrencyUtil.formatPrice(order.finalAmount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action buttons: Reorder + Rate
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text(
                    'Reorder',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    await ref.read(ordersProvider.notifier).reorder(order.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Items added to cart'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.pushNamed(RouteNames.cart);
                    }
                  },
                ),
              ),
            ),
            if (isDelivered) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryAmber,
                      side: const BorderSide(color: AppColors.primaryAmber),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.star_border, size: 16),
                    label: const Text(
                      'Rate',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.pushNamed(
                      RouteNames.rateOrder,
                      pathParameters: {'orderId': order.id},
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  bool _isTrackable(String status) =>
      status == 'picked_up' || status == 'ready';
}

// ---------------------------------------------------------------------------
// Animated status badge
// ---------------------------------------------------------------------------

class _AnimatedStatusBadge extends StatefulWidget {
  final String status;
  const _AnimatedStatusBadge({required this.status});

  @override
  State<_AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<_AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.7, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.status);
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              _statusLabel(widget.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order progress bar
// ---------------------------------------------------------------------------

class _OrderProgressBar extends StatelessWidget {
  final String status;
  const _OrderProgressBar({required this.status});

  double get _progress {
    switch (status) {
      case 'pending':
        return 0.1;
      case 'confirmed':
        return 0.3;
      case 'packing':
        return 0.5;
      case 'ready':
        return 0.7;
      case 'picked_up':
        return 0.85;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 4,
        backgroundColor: AppColors.divider,
        valueColor: AlwaysStoppedAnimation<Color>(_statusColor(status)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.statusPending;
    case 'confirmed':
      return AppColors.statusConfirmed;
    case 'packing':
      return AppColors.statusPacking;
    case 'ready':
      return AppColors.statusReady;
    case 'picked_up':
      return AppColors.statusPickedUp;
    case 'delivered':
      return AppColors.statusDelivered;
    case 'cancelled':
      return AppColors.statusCancelled;
    default:
      return AppColors.statusPending;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'confirmed':
      return 'Confirmed';
    case 'packing':
      return 'Packing';
    case 'ready':
      return 'Ready';
    case 'picked_up':
      return 'On the Way';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}
