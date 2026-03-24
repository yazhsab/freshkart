import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_vendor/core/models/order_model.dart';
import 'package:freshkart_vendor/features/orders/providers/orders_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NewOrderState {
  final List<OrderModel> pendingOrders;
  final bool isAlertActive;
  final bool isSoundPlaying;

  const NewOrderState({
    this.pendingOrders = const [],
    this.isAlertActive = false,
    this.isSoundPlaying = false,
  });

  NewOrderState copyWith({
    List<OrderModel>? pendingOrders,
    bool? isAlertActive,
    bool? isSoundPlaying,
  }) {
    return NewOrderState(
      pendingOrders: pendingOrders ?? this.pendingOrders,
      isAlertActive: isAlertActive ?? this.isAlertActive,
      isSoundPlaying: isSoundPlaying ?? this.isSoundPlaying,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class NewOrderNotifier extends StateNotifier<NewOrderState> {
  final Ref _ref;

  NewOrderNotifier(this._ref) : super(const NewOrderState());

  /// Compare incoming orders with current list; trigger alert if new ones found.
  void handleNewOrders(List<OrderModel> orders) {
    final pendingOnly = orders.where((o) => o.isPending).toList();
    final previousIds = state.pendingOrders.map((o) => o.id).toSet();

    // Find genuinely new orders (IDs not previously seen)
    final newArrivals = pendingOnly
        .where((o) => !previousIds.contains(o.id))
        .toList();

    state = state.copyWith(pendingOrders: pendingOnly);

    if (newArrivals.isNotEmpty) {
      triggerAlert(newArrivals.first);
    }
  }

  /// Activate alert state for a new incoming order.
  void triggerAlert(OrderModel order) {
    state = state.copyWith(isAlertActive: true, isSoundPlaying: true);
  }

  /// Dismiss the alert banner / sound.
  void dismissAlert() {
    state = state.copyWith(isAlertActive: false, isSoundPlaying: false);
  }

  /// Accept a pending order — updates status to confirmed.
  Future<bool> acceptOrder(String orderId) async {
    final success = await _ref
        .read(ordersProvider.notifier)
        .updateOrderStatus(orderId, 'confirmed');

    if (success) {
      final updated = state.pendingOrders
          .where((o) => o.id != orderId)
          .toList();
      state = state.copyWith(pendingOrders: updated);

      if (updated.isEmpty) {
        dismissAlert();
      }
    }
    return success;
  }

  /// Reject a pending order — updates status to cancelled with reason.
  Future<bool> rejectOrder(String orderId, String reason) async {
    final success = await _ref
        .read(ordersProvider.notifier)
        .updateOrderStatus(orderId, 'cancelled', cancelReason: reason);

    if (success) {
      final updated = state.pendingOrders
          .where((o) => o.id != orderId)
          .toList();
      state = state.copyWith(pendingOrders: updated);

      if (updated.isEmpty) {
        dismissAlert();
      }
    }
    return success;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final newOrderProvider = StateNotifierProvider<NewOrderNotifier, NewOrderState>(
  (ref) {
    return NewOrderNotifier(ref);
  },
);
