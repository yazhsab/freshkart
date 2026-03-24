import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';
import 'package:freshkart_delivery/features/delivery/providers/active_delivery_provider.dart';
import 'package:freshkart_delivery/features/delivery/widgets/delivery_map_widget.dart';
import 'package:freshkart_delivery/features/delivery/widgets/navigation_card.dart';

class DeliveryDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryDetailScreen> createState() =>
      _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends ConsumerState<DeliveryDetailScreen> {
  bool _itemsExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(deliveryProvider.notifier).fetchOrder(widget.orderId);
      ref
          .read(activeDeliveryProvider.notifier)
          .subscribeToOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final activeState = ref.watch(activeDeliveryProvider);
    final order = deliveryState.order;
    final phase = deliveryState.phase;

    // Listen for cancellation
    ref.listen<ActiveDeliveryState>(activeDeliveryProvider, (prev, next) {
      if (next.error == 'Order has been cancelled') {
        _showCancelledAlert();
      }
      if (next.order != null && prev?.order?.status != next.order!.status) {
        ref.read(deliveryProvider.notifier).updateOrder(next.order!);
      }
    });

    if (deliveryState.isLoading && order == null) {
      return Scaffold(
        backgroundColor: DeliveryColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: DeliveryColors.primary),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: DeliveryColors.background,
        appBar: AppBar(
          title: const Text('Delivery'),
          backgroundColor: DeliveryColors.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: DeliveryColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                deliveryState.error ?? 'Order not found',
                style: GoogleFonts.notoSans(
                  color: DeliveryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPickupPhase =
        phase == DeliveryPhase.goingToVendor ||
        phase == DeliveryPhase.pickupOtp;

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        backgroundColor: DeliveryColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: phase == DeliveryPhase.completed
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.go('/'),
              )
            : null,
        title: Text(
          isPickupPhase
              ? 'Pickup from ${order.vendorName}'
              : phase == DeliveryPhase.completed
              ? 'Delivery Complete'
              : 'Deliver to customer',
          style: GoogleFonts.notoSans(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: DeliveryColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top 40%: Map widget
          Expanded(
            flex: 4,
            child: DeliveryMapWidget(
              destName: isPickupPhase ? order.vendorName : order.customerName,
              destLat: isPickupPhase ? order.vendorLat : order.customerLat,
              destLng: isPickupPhase ? order.vendorLng : order.customerLng,
              pinColor: isPickupPhase
                  ? DeliveryColors.stepPickup
                  : DeliveryColors.stepDropoff,
              isVendor: isPickupPhase,
              distanceKm: isPickupPhase
                  ? order.distanceToVendor
                  : order.distanceToCustomer,
              estimatedMins: isPickupPhase
                  ? order.estimatedPickupMins
                  : order.estimatedDeliveryMins,
            ),
          ),

          // Bottom 60%: Navigation card
          Expanded(
            flex: 6,
            child: isPickupPhase
                ? _buildPickupCard(order, phase)
                : _buildDropoffCard(order, phase, activeState),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard(dynamic order, DeliveryPhase phase) {
    return NavigationCard(
      currentPhase: phase,
      destinationName: order.vendorName,
      destinationAddress: order.vendorAddress,
      distanceKm: order.distanceToVendor,
      estimatedMins: order.estimatedPickupMins,
      phoneNumber: order.vendorPhone,
      phoneLabel: 'Call Vendor',
      destLat: order.vendorLat,
      destLng: order.vendorLng,
      onReachedPressed: () {
        context.push('/delivery/${widget.orderId}/pickup-otp');
      },
      reachedButtonLabel: "I've reached the vendor",
      extraContent: _buildOrderItemsSection(order),
    );
  }

  Widget _buildDropoffCard(
    dynamic order,
    DeliveryPhase phase,
    ActiveDeliveryState activeState,
  ) {
    return NavigationCard(
      currentPhase: phase,
      destinationName: order.customerName,
      destinationAddress: order.deliveryAddress,
      distanceKm: order.distanceToCustomer,
      estimatedMins: order.estimatedDeliveryMins,
      phoneNumber: order.customerPhone,
      phoneLabel: 'Call Customer',
      destLat: order.customerLat,
      destLng: order.customerLng,
      onReachedPressed: () {
        context.push('/delivery/${widget.orderId}/delivery-otp');
      },
      reachedButtonLabel: "I've reached the customer",
      extraContent: Column(
        children: [
          // Payment info card
          _buildPaymentInfoCard(order),
          const SizedBox(height: 12),
          _buildOrderItemsSection(order),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(dynamic order) {
    final isCod = order.isCod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCod
            ? DeliveryColors.stepPickup.withOpacity(0.08)
            : DeliveryColors.stepDone.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCod
              ? DeliveryColors.stepPickup.withOpacity(0.2)
              : DeliveryColors.stepDone.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCod ? Icons.payments_outlined : Icons.check_circle_outline,
            color: isCod ? DeliveryColors.stepPickup : DeliveryColors.stepDone,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCod
                  ? 'Collect ${CurrencyUtil.format(order.finalAmount)} cash'
                  : 'Payment collected online',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCod
                    ? DeliveryColors.stepPickup
                    : DeliveryColors.stepDone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(dynamic order) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _itemsExpanded = !_itemsExpanded;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DeliveryColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: DeliveryColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'View order items (${order.itemCount})',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _itemsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded items list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildItemsList(),
          crossFadeState: _itemsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    final deliveryState = ref.watch(deliveryProvider);
    final items = deliveryState.items;
    final order = deliveryState.order;

    if (items.isEmpty && order != null && order.itemsSummary.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          order.itemsSummary,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            color: DeliveryColors.textSecondary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: DeliveryColors.primaryBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}x',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DeliveryColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.productName,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.unit,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCancelledAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text(
              'Order Cancelled',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'This order has been cancelled. You will be redirected to the home screen.',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: DeliveryColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: Text(
              'OK',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                color: DeliveryColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
