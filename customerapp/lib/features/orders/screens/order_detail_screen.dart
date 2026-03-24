import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/order_model.dart';
import 'package:freshkart_customer/core/router/route_names.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/utils/currency_util.dart';
import 'package:freshkart_customer/core/utils/date_util.dart';
import 'package:freshkart_customer/features/orders/widgets/order_status_stepper.dart';

// ---------------------------------------------------------------------------
// Provider to fetch a single order
// ---------------------------------------------------------------------------

final orderDetailProvider = FutureProvider.family<OrderModel, String>((
  ref,
  orderId,
) async {
  final response = await ApiClient().get(ApiEndpoints.orderById(orderId));
  final data = response.data as Map<String, dynamic>;
  return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _OrderDetailBody extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _StatusBanner(status: order.status),
          const SizedBox(height: 16),

          // Order summary card
          _OrderSummaryCard(order: order),
          const SizedBox(height: 16),

          // Delivery address
          if (order.deliveryAddress != null) ...[
            _DeliveryAddressCard(order: order),
            const SizedBox(height: 16),
          ],

          // Payment info
          _PaymentInfoCard(order: order),
          const SizedBox(height: 16),

          // Timeline stepper
          _TimelineCard(order: order),
          const SizedBox(height: 16),

          // Vendor contact
          if (order.vendor != null) ...[
            _VendorContactCard(order: order),
            const SizedBox(height: 16),
          ],

          // Cancellation info
          if (order.status == 'cancelled') ...[
            _CancellationCard(order: order),
            const SizedBox(height: 16),
          ],

          // Chat buttons
          _ChatButtons(order: order),
          const SizedBox(height: 16),

          // Action buttons
          _ActionButtons(order: order),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: config.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: config.color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order summary card
// ---------------------------------------------------------------------------

class _OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateUtil.formatOrderDate(order.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Items list
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.productImageUrl != null
                          ? Image.network(
                              item.productImageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _productPlaceholder(),
                            )
                          : _productPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity} x ${CurrencyUtil.formatPrice(item.unitPrice)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyUtil.formatPrice(item.totalPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 16),
            _PriceRow(label: 'Subtotal', amount: order.totalAmount),
            const SizedBox(height: 4),
            _PriceRow(label: 'Delivery Fee', amount: order.deliveryFee),
            if (order.discountAmount > 0) ...[
              const SizedBox(height: 4),
              _PriceRow(
                label: 'Discount',
                amount: -order.discountAmount,
                isGreen: true,
              ),
            ],
            const Divider(height: 16),
            _PriceRow(label: 'Total', amount: order.finalAmount, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textHint,
        size: 24,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price row helper
// ---------------------------------------------------------------------------

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final bool isGreen;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          CurrencyUtil.formatPrice(amount),
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isGreen ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery address card
// ---------------------------------------------------------------------------

class _DeliveryAddressCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryAddressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final addr = order.deliveryAddress!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    addr.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${addr.flatNo}, ${addr.area}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${addr.city}, ${addr.state} - ${addr.pincode}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment info card
// ---------------------------------------------------------------------------

class _PaymentInfoCard extends StatelessWidget {
  final OrderModel order;
  const _PaymentInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _paymentIcon(order.paymentMethod),
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _paymentLabel(order.paymentMethod),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                _PaymentStatusBadge(status: order.paymentStatus),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount Paid',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  CurrencyUtil.formatPrice(order.finalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'cod':
        return Icons.money;
      case 'razorpay':
        return Icons.payment;
      case 'phonepe':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'razorpay':
        return 'Razorpay';
      case 'phonepe':
        return 'PhonePe';
      default:
        return method.toUpperCase();
    }
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPaid ? AppColors.success : AppColors.warning).withOpacity(
          0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Pending',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPaid ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline card
// ---------------------------------------------------------------------------

class _TimelineCard extends StatelessWidget {
  final OrderModel order;
  const _TimelineCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            OrderStatusStepper(
              currentStatus: order.status,
              placedAt: order.createdAt,
              confirmedAt: order.vendorConfirmedAt,
              packedAt: order.packedAt,
              pickedUpAt: order.pickedUpAt,
              deliveredAt: order.deliveredAt,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vendor contact card
// ---------------------------------------------------------------------------

class _VendorContactCard extends StatelessWidget {
  final OrderModel order;
  const _VendorContactCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final vendor = order.vendor!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.backgroundGreen,
          child: const Icon(Icons.store, color: AppColors.primaryGreen),
        ),
        title: Text(
          vendor.shopName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Vendor'),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.primaryGreen),
          onPressed: () async {
            // Vendor phone is in address field for now; adjust if model changes
            final uri = Uri.parse('tel:${vendor.address}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cancellation card
// ---------------------------------------------------------------------------

class _CancellationCard extends StatelessWidget {
  final OrderModel order;
  const _CancellationCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.error.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            if (order.cancelReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${order.cancelReason}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (order.cancelledBy != null) ...[
              const SizedBox(height: 4),
              Text(
                'Cancelled by: ${order.cancelledBy}',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat buttons
// ---------------------------------------------------------------------------

class _ChatButtons extends StatelessWidget {
  final OrderModel order;
  const _ChatButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat with Vendor
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chat_outlined),
            label: const Text(
              'Chat with Vendor',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () => context.push(
              '/profile/chat?orderId=${order.id}&partyType=vendor&partyId=${order.vendorId}',
            ),
          ),
        ),
        // Chat with Driver (only when delivery agent is assigned)
        if (order.deliveryAgentId != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat_outlined),
              label: const Text(
                'Chat with Driver',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.push(
                '/profile/chat?orderId=${order.id}&partyType=delivery_agent&partyId=${order.deliveryAgentId}',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  final OrderModel order;
  const _ActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (order.status == 'picked_up')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.location_on),
              label: const Text(
                'Track Order',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.pushNamed(
                RouteNames.orderTracking,
                pathParameters: {'orderId': order.id},
              ),
            ),
          ),
        if (order.status == 'delivered') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.star_border),
              label: const Text(
                'Rate your order',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.pushNamed(
                RouteNames.rateOrder,
                pathParameters: {'orderId': order.id},
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status config helper
// ---------------------------------------------------------------------------

class _StatusConfigData {
  final Color color;
  final IconData icon;
  final String label;
  final String description;

  const _StatusConfigData({
    required this.color,
    required this.icon,
    required this.label,
    required this.description,
  });
}

_StatusConfigData _statusConfig(String status) {
  switch (status) {
    case 'pending':
      return const _StatusConfigData(
        color: AppColors.statusPending,
        icon: Icons.hourglass_empty,
        label: 'Order Placed',
        description: 'Waiting for vendor confirmation',
      );
    case 'confirmed':
      return const _StatusConfigData(
        color: AppColors.statusConfirmed,
        icon: Icons.check_circle_outline,
        label: 'Confirmed',
        description: 'Vendor has confirmed your order',
      );
    case 'packing':
      return const _StatusConfigData(
        color: AppColors.statusPacking,
        icon: Icons.inventory_2_outlined,
        label: 'Packing',
        description: 'Your order is being packed',
      );
    case 'ready':
      return const _StatusConfigData(
        color: AppColors.statusReady,
        icon: Icons.check_box_outlined,
        label: 'Ready for Pickup',
        description: 'Order is ready, waiting for rider',
      );
    case 'picked_up':
      return const _StatusConfigData(
        color: AppColors.statusPickedUp,
        icon: Icons.delivery_dining,
        label: 'On the Way',
        description: 'Rider is heading to your location',
      );
    case 'delivered':
      return const _StatusConfigData(
        color: AppColors.statusDelivered,
        icon: Icons.check_circle,
        label: 'Delivered',
        description: 'Order delivered successfully',
      );
    case 'cancelled':
      return const _StatusConfigData(
        color: AppColors.statusCancelled,
        icon: Icons.cancel,
        label: 'Cancelled',
        description: 'This order has been cancelled',
      );
    default:
      return const _StatusConfigData(
        color: AppColors.statusPending,
        icon: Icons.info_outline,
        label: 'Unknown',
        description: '',
      );
  }
}
