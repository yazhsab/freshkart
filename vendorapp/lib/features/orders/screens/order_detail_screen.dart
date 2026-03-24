import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/utils/date_util.dart';
import 'package:freshkart_vendor/core/models/order_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/status_badge.dart';
import 'package:freshkart_vendor/features/shared/widgets/loading_overlay.dart';
import 'package:freshkart_vendor/features/orders/providers/orders_provider.dart';
import 'package:freshkart_vendor/features/orders/providers/new_order_provider.dart';
import 'package:freshkart_vendor/features/orders/widgets/order_items_list.dart';
import 'package:freshkart_vendor/features/orders/widgets/order_status_timeline.dart';
import 'package:freshkart_vendor/features/orders/widgets/countdown_timer_widget.dart';

// ---------------------------------------------------------------------------
// Provider to fetch single order detail
// ---------------------------------------------------------------------------

final orderDetailProvider = FutureProvider.family<OrderModel, String>((
  ref,
  orderId,
) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
      headers: {
        'Authorization':
            'Bearer ${SupabaseConfig.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    ),
  );

  final response = await dio.get(VendorApiEndpoints.orderById(orderId));
  final data = response.data['data'] ?? response.data;
  return OrderModel.fromJson(data as Map<String, dynamic>);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isUpdating = false;
  final Set<String> _packedItemIds = {};
  bool get _allItemsPacked => _packedItemIds.isNotEmpty;

  Future<void> _updateStatus(String newStatus, {String? cancelReason}) async {
    setState(() => _isUpdating = true);

    final success = await ref
        .read(ordersProvider.notifier)
        .updateOrderStatus(
          widget.orderId,
          newStatus,
          cancelReason: cancelReason,
        );

    setState(() => _isUpdating = false);

    if (success && mounted) {
      ref.invalidate(orderDetailProvider(widget.orderId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${_statusLabel(newStatus)}'),
          backgroundColor: VendorColors.primary,
        ),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'accepted';
      case 'packing':
        return 'packing started';
      case 'ready':
        return 'marked ready';
      case 'cancelled':
        return 'rejected';
      default:
        return 'updated';
    }
  }

  Future<void> _showRejectDialog() async {
    final reasons = [
      'Items out of stock',
      'Shop closing soon',
      'Too many orders',
      'Customer request',
      'Other',
    ];
    String? selectedReason;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Reject Order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a reason:',
                style: TextStyle(
                  fontSize: 14,
                  color: VendorColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: VendorColors.primary,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() => selectedReason = val);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, selectedReason)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorColors.cancelledOrder,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _updateStatus('cancelled', cancelReason: result);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: VendorColors.surface,
        foregroundColor: VendorColors.textPrimary,
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(VendorColors.primary),
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: VendorColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load order',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(orderDetailProvider(widget.orderId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (order) =>
            LoadingOverlay(isLoading: _isUpdating, child: _buildContent(order)),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(order),
                const SizedBox(height: 16),
                _buildCustomerSection(order),
                const SizedBox(height: 16),
                _buildItemsSection(order),
                const SizedBox(height: 16),
                _buildPricingSection(order),
                const SizedBox(height: 16),
                _buildPaymentSection(order),
                const SizedBox(height: 16),
                _buildTimelineSection(order),
                if (order.deliveryAgentName != null &&
                    (order.isPickedUp || order.isReady)) ...[
                  const SizedBox(height: 16),
                  _buildDeliveryAgentSection(order),
                ],
                if (order.isDelivered) ...[
                  const SizedBox(height: 16),
                  _buildEarningsSummary(order),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildActionBar(order),
      ],
    );
  }

  Widget _buildHeaderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              _statusBadge(order),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: VendorColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Placed ${DateUtil.formatDateTime(order.createdAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: VendorColors.textSecondary,
                ),
              ),
            ],
          ),
          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VendorColors.pendingAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: VendorColors.pendingAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: VendorColors.pendingAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.specialInstructions!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: VendorColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VendorColors.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    order.customerFirstName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerFirstName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: VendorColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.customerArea,
                            style: const TextStyle(
                              fontSize: 13,
                              color: VendorColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VendorColors.fieldBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: VendorColors.textHint,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Full address shared with delivery agent only',
                    style: TextStyle(
                      fontSize: 12,
                      color: VendorColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(OrderModel order) {
    final showCheckboxes = order.isPacking;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: VendorColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OrderItemsList(
            items: order.items,
            showCheckboxes: showCheckboxes,
            onCheckedChanged: (checkedIds) {
              setState(() {
                _packedItemIds.clear();
                _packedItemIds.addAll(checkedIds);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', order.totalAmount),
          const SizedBox(height: 8),
          _priceRow('Delivery Fee', order.deliveryFee),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _priceRow(
              'Discount',
              -order.discountAmount,
              color: VendorColors.earningsGreen,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(color: VendorColors.divider),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textPrimary,
                ),
              ),
              Text(
                CurrencyUtil.formatPrice(order.finalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: VendorColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {Color? color}) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: VendorColors.textSecondary,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}${CurrencyUtil.formatPrice(amount.abs())}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? VendorColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(OrderModel order) {
    final isPaid =
        order.paymentStatus == 'paid' || order.paymentStatus == 'captured';
    final isOnline = order.isPaidOnline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOnline
                  ? VendorColors.confirmedOrder.withValues(alpha: 0.1)
                  : VendorColors.pendingAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOnline
                  ? Icons.account_balance_wallet_rounded
                  : Icons.money_rounded,
              color: isOnline
                  ? VendorColors.confirmedOrder
                  : VendorColors.pendingAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.paymentMethod == 'cod'
                      ? 'Cash on Delivery'
                      : order.paymentMethod == 'upi'
                      ? 'UPI Payment'
                      : 'Online Payment',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VendorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'Paid'
                      : 'Collect ${CurrencyUtil.formatPrice(order.finalAmount)} cash',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPaid
                        ? VendorColors.primary
                        : VendorColors.pendingAmber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isPaid)
            const Icon(
              Icons.check_circle_rounded,
              color: VendorColors.primary,
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          OrderStatusTimeline(order: order),
        ],
      ),
    );
  }

  Widget _buildDeliveryAgentSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Agent',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: VendorColors.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: VendorColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deliveryAgentName ?? 'Agent',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textPrimary,
                      ),
                    ),
                    if (order.deliveryAgentPhone != null)
                      Text(
                        order.deliveryAgentPhone!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: VendorColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (order.deliveryAgentPhone != null)
                IconButton(
                  onPressed: () => _callPhone(order.deliveryAgentPhone!),
                  icon: const Icon(Icons.phone_rounded),
                  color: VendorColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: VendorColors.primaryBg,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary(OrderModel order) {
    final commission =
        order.totalAmount * (VendorAppConfig.platformCommissionPct / 100);
    final netEarnings = order.totalAmount - commission;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.earningsGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VendorColors.earningsGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: VendorColors.earningsGreen,
              ),
              SizedBox(width: 8),
              Text(
                'Earnings Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.earningsGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _earningsRow('Order Amount', order.totalAmount),
          const SizedBox(height: 4),
          _earningsRow(
            'Platform Fee (${VendorAppConfig.platformCommissionPct.toStringAsFixed(0)}%)',
            -commission,
          ),
          const SizedBox(height: 8),
          const Divider(color: VendorColors.divider),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Earnings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.earningsGreen,
                ),
              ),
              Text(
                CurrencyUtil.formatPrice(netEarnings),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: VendorColors.earningsGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earningsRow(String label, double amount) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: VendorColors.textSecondary,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}${CurrencyUtil.formatPrice(amount.abs())}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isNegative
                ? VendorColors.cancelledOrder
                : VendorColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(OrderModel order) {
    // No actions for delivered/cancelled/picked_up
    if (order.isDelivered || order.isCancelled || order.isPickedUp) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(child: _buildActionContent(order)),
    );
  }

  Widget _buildActionContent(OrderModel order) {
    // Pending: Accept + Reject
    if (order.isPending) {
      return Row(
        children: [
          CountdownTimerWidget(
            orderCreatedAt: order.createdAt,
            totalSeconds: VendorAppConfig.orderAutoConfirmSeconds,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _showRejectDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: VendorColors.cancelledOrder,
                  side: const BorderSide(
                    color: VendorColors.cancelledOrder,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _updateStatus('confirmed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorColors.primaryLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Confirmed: Start Packing
    if (order.isConfirmed) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus('packing'),
          icon: const Icon(Icons.inventory_2_outlined, size: 20),
          label: const Text(
            'Start Packing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: VendorColors.packingOrder,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // Packing: items checklist + Mark Ready
    if (order.isPacking) {
      final allPacked =
          order.items.isNotEmpty && _packedItemIds.length == order.items.length;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allPacked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: VendorColors.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: VendorColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'All items packed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: allPacked ? () => _updateStatus('ready') : null,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Mark Ready for Pickup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorColors.readyOrder,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: VendorColors.readyOrder.withValues(
                  alpha: 0.4,
                ),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Ready: show OTP + waiting
    if (order.isReady) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.deliveryOtp != null && order.deliveryOtp!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: VendorColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VendorColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Delivery OTP',
                    style: TextStyle(
                      fontSize: 13,
                      color: VendorColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.deliveryOtp!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: VendorColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    VendorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Waiting for delivery agent to pick up...',
                style: TextStyle(
                  fontSize: 13,
                  color: VendorColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statusBadge(OrderModel order) {
    if (order.isPending) return StatusBadge.pending();
    if (order.isConfirmed) return StatusBadge.confirmed();
    if (order.isPacking) return StatusBadge.packing();
    if (order.isReady) return StatusBadge.ready();
    if (order.isDelivered) return StatusBadge.delivered();
    if (order.isCancelled) return StatusBadge.cancelled();
    return StatusBadge(label: order.status, color: VendorColors.textSecondary);
  }
}
