import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/config/app_config.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';
import 'package:freshkart_delivery/features/shared/widgets/empty_state_widget.dart';
import 'package:freshkart_delivery/features/home/providers/home_provider.dart';

class AvailableOrdersList extends StatelessWidget {
  final List<DeliveryOrderModel> orders;

  const AvailableOrdersList({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Orders near you',
              style: GoogleFonts.notoSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: DeliveryColors.textPrimary,
              ),
            ),
            if (orders.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DeliveryColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${orders.length}',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: orders.map((order) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AvailableOrderCard(order: order),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const EmptyStateWidget(
            icon: Icons.delivery_dining,
            title: 'No orders right now',
            subtitle: 'Stay online \u2014 orders will appear here',
          ),
          const SizedBox(height: 8),
          Text(
            '\u0B86\u0BB0\u0BCD\u0B9F\u0BB0\u0BCD\u0B95\u0BB3\u0BCD \u0BB5\u0BB0\u0BC1\u0BAE\u0BCD \u0BB5\u0BB0\u0BC8 \u0B95\u0BBE\u0BA4\u0BCD\u0BA4\u0BBF\u0BB0\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: DeliveryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableOrderCard extends ConsumerStatefulWidget {
  final DeliveryOrderModel order;

  const _AvailableOrderCard({required this.order});

  @override
  ConsumerState<_AvailableOrderCard> createState() =>
      _AvailableOrderCardState();
}

class _AvailableOrderCardState extends ConsumerState<_AvailableOrderCard>
    with SingleTickerProviderStateMixin {
  late Timer _countdownTimer;
  double _progress = 1.0;
  int _remainingSeconds = DeliveryAppConfig.orderAcceptTimeoutSeconds;
  bool _isAccepting = false;
  bool _isExpired = false;
  late AnimationController _borderPulseController;
  late Animation<Color?> _borderColorAnimation;

  bool get _isNewOrder {
    final assignedAt = widget.order.assignedAt;
    if (assignedAt == null) return false;
    return DateTime.now().difference(assignedAt).inSeconds < 30;
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = DeliveryAppConfig.orderAcceptTimeoutSeconds;
    _progress = 1.0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        _progress =
            _remainingSeconds / DeliveryAppConfig.orderAcceptTimeoutSeconds;

        if (_remainingSeconds <= 0) {
          _isExpired = true;
          _countdownTimer.cancel();
        }
      });
    });

    // Border pulse for new orders
    _borderPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _borderColorAnimation =
        ColorTween(
          begin: Colors.transparent,
          end: DeliveryColors.newOrder,
        ).animate(
          CurvedAnimation(
            parent: _borderPulseController,
            curve: Curves.easeInOut,
          ),
        );

    if (_isNewOrder) {
      _borderPulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _borderPulseController.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder() async {
    if (_isAccepting || _isExpired) return;
    setState(() => _isAccepting = true);
    _countdownTimer.cancel();

    try {
      await ref.read(homeProvider.notifier).acceptOrder(widget.order.id);
      if (mounted) {
        context.push('/delivery/${widget.order.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return const SizedBox.shrink();
    }

    final order = widget.order;
    final deliveryEarnings = DeliveryAppConfig.calculateDeliveryFee(
      order.totalDistance,
    );

    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: DeliveryColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: _isNewOrder
                ? Border.all(
                    color: _borderColorAnimation.value ?? Colors.transparent,
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Order # + time since ready
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                Text(
                  order.assignedAt != null
                      ? DateUtil.timeAgo(order.assignedAt!)
                      : 'Just now',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Vendor info
            Row(
              children: [
                const Icon(
                  Icons.store_rounded,
                  size: 16,
                  color: DeliveryColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.vendorName,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DeliveryColors.textPrimary,
                        ),
                      ),
                      Text(
                        order.vendorAddress,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: DeliveryColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (order.distanceToVendor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DeliveryColors.primaryBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${order.distanceToVendor!.toStringAsFixed(1)} km',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DeliveryColors.primary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Delivery destination
            Row(
              children: [
                const Icon(
                  Icons.home_rounded,
                  size: 16,
                  color: DeliveryColors.stepDropoff,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerArea,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textPrimary,
                    ),
                  ),
                ),
                if (order.distanceToCustomer != null)
                  Text(
                    '${order.distanceToCustomer!.toStringAsFixed(1)} km drop',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Container(height: 1, color: DeliveryColors.divider),

            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                Text(
                  '${order.itemCount} items',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
                _separator(),
                Text(
                  CurrencyUtil.format(order.finalAmount),
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                if (order.isCod) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DeliveryColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: DeliveryColors.warning.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'COD',
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DeliveryColors.warning,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Earnings ',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
                Text(
                  CurrencyUtil.format(deliveryEarnings),
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.earningsTeal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Accept Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _acceptOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DeliveryColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DeliveryColors.primary.withOpacity(
                    0.6,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.notoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Accept Delivery'),
              ),
            ),

            const SizedBox(height: 6),

            // Countdown progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingSeconds > 5
                      ? DeliveryColors.primary
                      : DeliveryColors.newOrder,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Countdown text
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_remainingSeconds}s',
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  color: _remainingSeconds > 5
                      ? DeliveryColors.textSecondary
                      : DeliveryColors.newOrder,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '\u2022',
        style: TextStyle(
          color: DeliveryColors.textSecondary.withOpacity(0.5),
          fontSize: 10,
        ),
      ),
    );
  }
}
