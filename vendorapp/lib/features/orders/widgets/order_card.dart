import 'package:flutter/material.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/utils/date_util.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/models/order_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/status_badge.dart';
import 'package:freshkart_vendor/features/orders/widgets/countdown_timer_widget.dart';

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final ValueChanged<String>? onUpdateStatus;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onUpdateStatus,
    this.onTap,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  bool get _isNewAndRecent {
    if (!widget.order.isPending) return false;
    final age = DateTime.now().difference(widget.order.createdAt).inSeconds;
    return age < 30;
  }

  @override
  void initState() {
    super.initState();
    if (_isNewAndRecent) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Color get _leftBorderColor {
    if (widget.order.isPending) return VendorColors.newOrder;
    if (widget.order.isConfirmed) return VendorColors.confirmedOrder;
    if (widget.order.isPacking) return VendorColors.packingOrder;
    if (widget.order.isReady) return VendorColors.readyOrder;
    if (widget.order.isDelivered) return VendorColors.primary;
    if (widget.order.isCancelled) return VendorColors.cancelledOrder;
    return VendorColors.divider;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    final cardContent = IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: _leftBorderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(order),
                    const SizedBox(height: 8),
                    _buildCustomerRow(order),
                    const SizedBox(height: 4),
                    _buildAmountRow(order),
                    if (order.specialInstructions != null &&
                        order.specialInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSpecialInstructions(order),
                    ],
                    const SizedBox(height: 12),
                    _buildActions(order),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Pulsing green border for orders < 30s old
    if (_isNewAndRecent && _pulseAnimation != null) {
      return AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: VendorColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VendorColors.primaryLight.withValues(
                  alpha: 0.3 + (_pulseAnimation!.value * 0.7),
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: VendorColors.primaryLight.withValues(
                    alpha: _pulseAnimation!.value * 0.15,
                  ),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: cardContent,
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: cardContent,
    );
  }

  Widget _buildHeader(OrderModel order) {
    return Row(
      children: [
        if (order.isPending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: VendorColors.newOrder,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        if (order.isPending) const SizedBox(width: 8),
        Text(
          '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: VendorColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          DateUtil.timeAgo(order.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: VendorColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerRow(OrderModel order) {
    return Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: 14,
          color: VendorColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          order.customerFirstName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: VendorColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.location_on_outlined,
          size: 14,
          color: VendorColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            order.customerArea,
            style: const TextStyle(
              fontSize: 12,
              color: VendorColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(OrderModel order) {
    return Row(
      children: [
        Text(
          '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 13,
            color: VendorColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          CurrencyUtil.formatPrice(order.finalAmount),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: VendorColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VendorColors.pendingAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notes_rounded,
            size: 14,
            color: VendorColors.pendingAmber,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              order.specialInstructions!,
              style: const TextStyle(
                fontSize: 12,
                color: VendorColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(OrderModel order) {
    // Pending: countdown + accept/reject
    if (order.isPending) {
      return Row(
        children: [
          CountdownTimerWidget(
            orderCreatedAt: order.createdAt,
            totalSeconds: VendorAppConfig.orderAutoConfirmSeconds,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: widget.onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: VendorColors.cancelledOrder,
                  side: const BorderSide(color: VendorColors.cancelledOrder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: widget.onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Active: start packing or mark ready
    if (order.isConfirmed) {
      return _actionButton(
        label: 'Start Packing',
        icon: Icons.inventory_2_outlined,
        color: VendorColors.packingOrder,
        onPressed: () => widget.onUpdateStatus?.call('packing'),
      );
    }

    if (order.isPacking) {
      return _actionButton(
        label: 'Mark Ready',
        icon: Icons.check_circle_outline,
        color: VendorColors.readyOrder,
        onPressed: () => widget.onUpdateStatus?.call('ready'),
      );
    }

    // Ready: delivery OTP + agent info
    if (order.isReady) {
      return _buildReadyInfo(order);
    }

    // Done: status badge + earnings
    if (order.isDone) {
      return Row(
        children: [
          if (order.isDelivered)
            StatusBadge.delivered()
          else
            StatusBadge.cancelled(),
          const Spacer(),
          if (order.isDelivered)
            Text(
              CurrencyUtil.formatPrice(order.vendorEarnings),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VendorColors.earningsGreen,
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildReadyInfo(OrderModel order) {
    final waitMinutes = DateTime.now()
        .difference(order.packedAt ?? order.createdAt)
        .inMinutes;
    final isLongWait = waitMinutes > 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.deliveryOtp != null && order.deliveryOtp!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VendorColors.primaryBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: VendorColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pin_outlined,
                  size: 16,
                  color: VendorColors.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'OTP: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: VendorColors.textSecondary,
                  ),
                ),
                Text(
                  order.deliveryOtp!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: VendorColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (order.deliveryAgentName != null)
          Row(
            children: [
              const Icon(
                Icons.delivery_dining,
                size: 16,
                color: VendorColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                order.deliveryAgentName!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: VendorColors.textPrimary,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLongWait
                        ? VendorColors.error
                        : VendorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for delivery pickup...',
                style: TextStyle(
                  fontSize: 12,
                  color: isLongWait
                      ? VendorColors.error
                      : VendorColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isLongWait) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: VendorColors.error,
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
