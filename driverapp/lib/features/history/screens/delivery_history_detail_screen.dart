import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';
import 'package:freshkart_delivery/core/config/app_config.dart';

final deliveryDetailProvider =
    FutureProvider.family<DeliveryOrderModel, String>((ref, orderId) async {
      final response = await ApiClient.instance.get(
        ApiEndpoints.deliveryDetails(orderId),
      );
      final data = response.data as Map<String, dynamic>;
      final orderData = data['delivery'] as Map<String, dynamic>? ?? data;
      return DeliveryOrderModel.fromJson(orderData);
    });

class DeliveryHistoryDetailScreen extends ConsumerWidget {
  final String orderId;

  const DeliveryHistoryDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(deliveryDetailProvider(orderId));

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Delivery Details',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            color: DeliveryColors.textPrimary,
          ),
        ),
        backgroundColor: DeliveryColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DeliveryColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: DeliveryColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load details',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: DeliveryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        data: (delivery) => _DetailContent(delivery: delivery),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final DeliveryOrderModel delivery;

  const _DetailContent({required this.delivery});

  double get _totalDistance =>
      (delivery.pickupDistanceKm ?? 0) + (delivery.dropDistanceKm ?? 0);

  Duration? get _deliveryDuration {
    if (delivery.createdAt != null && delivery.deliveredAt != null) {
      return delivery.deliveredAt!.difference(delivery.createdAt!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          _buildOrderHeader(),
          const SizedBox(height: 16),

          // Delivery timeline
          _buildTimelineCard(),
          const SizedBox(height: 16),

          // Duration and distance
          _buildDurationDistanceRow(),
          const SizedBox(height: 16),

          // Earnings breakdown
          _buildEarningsCard(),
          const SizedBox(height: 16),

          // Order details
          _buildOrderDetailsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: delivery.isDelivered
                  ? DeliveryColors.stepDone.withOpacity(0.1)
                  : DeliveryColors.newOrder.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              delivery.isDelivered ? Icons.check_circle : Icons.cancel,
              color: delivery.isDelivered
                  ? DeliveryColors.stepDone
                  : DeliveryColors.newOrder,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery #FK${delivery.orderNumber}',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  delivery.isDelivered
                      ? 'Successfully delivered'
                      : delivery.isCancelled
                      ? 'Delivery failed'
                      : delivery.status.replaceAll('_', ' '),
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Timeline',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _TimelineStep(
            title: 'Order Accepted',
            time: delivery.createdAt,
            isFirst: true,
            isCompleted: true,
          ),
          _TimelineStep(
            title: 'Reached Vendor',
            time: delivery.vendorConfirmedAt,
            isCompleted: delivery.vendorConfirmedAt != null,
          ),
          _TimelineStep(
            title: 'Pickup Confirmed',
            time: delivery.pickedUpAt,
            isCompleted: delivery.pickedUpAt != null,
          ),
          _TimelineStep(
            title: 'Reached Customer',
            time: delivery.deliveredAt != null
                ? delivery.deliveredAt!.subtract(const Duration(minutes: 2))
                : null,
            isCompleted: delivery.deliveredAt != null,
          ),
          _TimelineStep(
            title: delivery.isDelivered ? 'Delivered' : 'Cancelled',
            time: delivery.deliveredAt ?? delivery.cancelledAt,
            isLast: true,
            isCompleted:
                delivery.deliveredAt != null || delivery.cancelledAt != null,
            isFailed: delivery.isCancelled,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationDistanceRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DeliveryColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DeliveryColors.divider),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: DeliveryColors.primary,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  _deliveryDuration != null
                      ? DateUtil.formatDuration(_deliveryDuration!)
                      : '--',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DeliveryColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DeliveryColors.divider),
            ),
            child: Column(
              children: [
                Icon(Icons.route, color: DeliveryColors.primary, size: 24),
                const SizedBox(height: 8),
                Text(
                  '${_totalDistance.toStringAsFixed(1)} km',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Distance',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    final baseFee = DeliveryAppConfig.baseDeliveryFee;
    final totalEarnings = delivery.deliveryEarnings ?? baseFee;
    final bonus = (totalEarnings - baseFee).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Breakdown',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _EarningsRow(label: 'Base Fee', amount: CurrencyUtil.format(baseFee)),
          if (bonus > 0)
            _EarningsRow(
              label: 'Bonus',
              amount: CurrencyUtil.format(bonus),
              color: DeliveryColors.bonusGold,
            ),
          const Divider(height: 20, color: DeliveryColors.divider),
          _EarningsRow(
            label: 'Total',
            amount: CurrencyUtil.format(totalEarnings),
            isBold: true,
            color: DeliveryColors.earningsTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Vendor
          _DetailRow(
            icon: Icons.store,
            label: 'Vendor',
            value: delivery.vendorName ?? 'Unknown',
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              delivery.vendorFullAddress,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: DeliveryColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Customer
          _DetailRow(
            icon: Icons.person,
            label: 'Customer',
            value: delivery.customerName ?? 'Unknown',
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              delivery.customerFullAddress,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: DeliveryColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 24, color: DeliveryColors.divider),

          // Items & Amount
          _DetailRow(
            icon: Icons.shopping_bag,
            label: 'Items',
            value:
                '${delivery.itemCount} item${delivery.itemCount != 1 ? 's' : ''}',
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.payments,
            label: 'Order Amount',
            value: CurrencyUtil.format(delivery.finalAmount),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.credit_card,
            label: 'Payment',
            value: delivery.paymentMethod == 'cod'
                ? 'Cash on Delivery'
                : 'Online Payment',
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final DateTime? time;
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final bool isFailed;

  const _TimelineStep({
    required this.title,
    this.time,
    this.isFirst = false,
    this.isLast = false,
    this.isCompleted = false,
    this.isFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isFailed
        ? DeliveryColors.newOrder
        : isCompleted
        ? DeliveryColors.stepDone
        : DeliveryColors.stepPending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? dotColor
                          : DeliveryColors.stepPending.withOpacity(0.3),
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCompleted
                        ? null
                        : Border.all(
                            color: DeliveryColors.stepPending,
                            width: 2,
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? dotColor
                          : DeliveryColors.stepPending.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: isCompleted
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isCompleted
                          ? DeliveryColors.textPrimary
                          : DeliveryColors.textSecondary,
                    ),
                  ),
                  if (time != null)
                    Text(
                      DateUtil.formatTime(time!),
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;
  final Color? color;

  const _EarningsRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: DeliveryColors.textPrimary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? DeliveryColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DeliveryColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.notoSans(
            fontSize: 13,
            color: DeliveryColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DeliveryColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
