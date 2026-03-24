import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_delivery/features/delivery/screens/delivery_detail_screen.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';

/// Dropoff screen wraps DeliveryDetailScreen and ensures it starts
/// in the dropoff phase (goingToCustomer). The delivery_detail_screen
/// already adapts its UI based on the current phase, so this serves
/// as a named route entry point for the dropoff flow.
class DropoffScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DropoffScreen({super.key, required this.orderId});

  @override
  ConsumerState<DropoffScreen> createState() => _DropoffScreenState();
}

class _DropoffScreenState extends ConsumerState<DropoffScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(deliveryProvider.notifier);
      notifier.setPhase(DeliveryPhase.goingToCustomer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryDetailScreen(orderId: widget.orderId);
  }
}
