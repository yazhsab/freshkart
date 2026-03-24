import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_delivery/features/delivery/screens/delivery_detail_screen.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';

/// Pickup screen wraps DeliveryDetailScreen and ensures it starts
/// in the pickup phase (goingToVendor). The delivery_detail_screen
/// already adapts its UI based on the current phase, so this serves
/// as a named route entry point for the pickup flow.
class PickupScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PickupScreen({super.key, required this.orderId});

  @override
  ConsumerState<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends ConsumerState<PickupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(deliveryProvider.notifier);
      notifier.setPhase(DeliveryPhase.goingToVendor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryDetailScreen(orderId: widget.orderId);
  }
}
