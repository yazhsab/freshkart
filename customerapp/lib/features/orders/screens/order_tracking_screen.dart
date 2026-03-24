import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/utils/currency_util.dart';
import 'package:freshkart_customer/features/orders/providers/tracking_provider.dart';
import 'package:freshkart_customer/features/orders/widgets/tracking_map_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  late final ConfettiController _confettiController;
  bool _deliveredDialogShown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showDeliveredDialog() {
    if (_deliveredDialogShown) return;
    _deliveredDialogShown = true;
    _confettiController.play();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 56,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order Delivered!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Your order has been delivered successfully. Enjoy your items!',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider(widget.orderId));

    // Trigger delivered celebration
    if (tracking.order?.status == 'delivered') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDeliveredDialog();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Top 40%: Map area
              Expanded(flex: 4, child: _MapArea(tracking: tracking)),
              // Bottom 60%: Details sheet
              Expanded(
                flex: 6,
                child: _BottomSheet(
                  tracking: tracking,
                  orderId: widget.orderId,
                ),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primaryGreen,
                AppColors.lightGreen,
                AppColors.primaryAmber,
                AppColors.info,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map area (top 40%)
// ---------------------------------------------------------------------------

class _MapArea extends StatelessWidget {
  final TrackingState tracking;
  const _MapArea({required this.tracking});

  @override
  Widget build(BuildContext context) {
    final order = tracking.order;
    final destLat = order?.deliveryAddress?.lat ?? 0;
    final destLng = order?.deliveryAddress?.lng ?? 0;
    final destAddr = order?.deliveryAddress != null
        ? '${order!.deliveryAddress!.flatNo}, ${order.deliveryAddress!.area}'
        : 'Delivery address';

    return Stack(
      children: [
        TrackingMapWidget(
          agentLat: tracking.agentLat,
          agentLng: tracking.agentLng,
          destLat: destLat,
          destLng: destLng,
          destAddress: destAddr,
        ),
        // ETA badge
        if (tracking.estimatedMinutes != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Arriving in ${tracking.estimatedMinutes} mins',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet (bottom 60%)
// ---------------------------------------------------------------------------

class _BottomSheet extends StatelessWidget {
  final TrackingState tracking;
  final String orderId;

  const _BottomSheet({required this.tracking, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = tracking.order;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: tracking.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order # + status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order?.orderNumber ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      _StatusBadge(status: order?.status ?? 'pending'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Delivery partner card
                  if (tracking.agentName != null) ...[
                    _DeliveryPartnerCard(tracking: tracking),
                    const SizedBox(height: 20),
                  ],

                  // Status progress bar
                  _StatusProgressBar(status: order?.status ?? 'pending'),
                  const SizedBox(height: 20),

                  // Collapsed order summary
                  if (order != null) _CollapsedOrderSummary(order: order),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery partner card
// ---------------------------------------------------------------------------

class _DeliveryPartnerCard extends StatelessWidget {
  final TrackingState tracking;
  const _DeliveryPartnerCard({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Photo placeholder
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Partner',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tracking.agentName ?? 'Rider',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Call button
          if (tracking.agentPhone != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                onPressed: () async {
                  final uri = Uri.parse('tel:${tracking.agentPhone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status progress bar
// ---------------------------------------------------------------------------

class _StatusProgressBar extends StatelessWidget {
  final String status;
  const _StatusProgressBar({required this.status});

  static const _steps = ['confirmed', 'packing', 'picked_up', 'delivered'];
  static const _stepLabels = ['Confirmed', 'Packing', 'Picked up', 'Delivered'];

  int get _currentIndex {
    final idx = _steps.indexOf(status);
    return idx >= 0 ? idx : -1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < _currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isCompleted
                      ? AppColors.primaryGreen
                      : AppColors.divider,
                ),
              );
            }
            // Dot
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex <= _currentIndex;
            final isCurrent = stepIndex == _currentIndex;
            return _ProgressDot(isCompleted: isCompleted, isCurrent: isCurrent);
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _stepLabels
              .map(
                (label) => SizedBox(
                  width: 64,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ProgressDot extends StatefulWidget {
  final bool isCompleted;
  final bool isCurrent;
  const _ProgressDot({required this.isCompleted, required this.isCurrent});

  @override
  State<_ProgressDot> createState() => _ProgressDotState();
}

class _ProgressDotState extends State<_ProgressDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isCurrent) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ProgressDot old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCurrent && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCompleted) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 2),
        ),
      );
    }

    if (widget.isCurrent) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final scale = 1.0 + _controller.value * 0.35;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen,
      ),
      child: const Icon(Icons.check, size: 10, color: Colors.white),
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsed order summary
// ---------------------------------------------------------------------------

class _CollapsedOrderSummary extends StatelessWidget {
  final dynamic order;
  const _CollapsedOrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Row(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            CurrencyUtil.formatPrice(order.finalAmount as double),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
      children: [
        ...order.items.map<Widget>(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '${item.quantity}x',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.productName as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  CurrencyUtil.formatPrice(item.totalPrice as double),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
