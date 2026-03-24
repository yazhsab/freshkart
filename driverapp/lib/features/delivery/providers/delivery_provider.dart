import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/models/order_item_model.dart';

enum DeliveryPhase {
  goingToVendor,
  pickupOtp,
  goingToCustomer,
  deliveryOtp,
  completed,
}

class DeliveryState {
  final DeliveryOrderModel? order;
  final List<OrderItemModel> items;
  final DeliveryPhase phase;
  final bool isLoading;
  final String? error;

  const DeliveryState({
    this.order,
    this.items = const [],
    this.phase = DeliveryPhase.goingToVendor,
    this.isLoading = false,
    this.error,
  });

  DeliveryState copyWith({
    DeliveryOrderModel? order,
    List<OrderItemModel>? items,
    DeliveryPhase? phase,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryState(
      order: order ?? this.order,
      items: items ?? this.items,
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  DeliveryNotifier() : super(const DeliveryState());

  Future<void> fetchOrder(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.deliveryDetails(orderId),
      );

      final data = response.data as Map<String, dynamic>;
      final orderData = data['order'] ?? data;
      final order = DeliveryOrderModel.fromJson(
        orderData as Map<String, dynamic>,
      );

      List<OrderItemModel> items = [];
      if (data['items'] != null) {
        items = (data['items'] as List<dynamic>)
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final phase = getCurrentPhase(order);

      state = state.copyWith(
        order: order,
        items: items,
        phase: phase,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  DeliveryPhase getCurrentPhase(DeliveryOrderModel order) {
    final status = order.status.toLowerCase();

    switch (status) {
      case 'assigned':
      case 'ready':
      case 'heading_to_vendor':
      case 'at_vendor':
        return DeliveryPhase.goingToVendor;
      case 'picking_up':
        return DeliveryPhase.pickupOtp;
      case 'picked_up':
      case 'in_transit':
      case 'heading_to_customer':
        return DeliveryPhase.goingToCustomer;
      case 'at_customer':
        return DeliveryPhase.deliveryOtp;
      case 'delivered':
      case 'completed':
        return DeliveryPhase.completed;
      default:
        return DeliveryPhase.goingToVendor;
    }
  }

  void updateFromRealtime(Map<String, dynamic> data) {
    final updatedOrder = DeliveryOrderModel.fromJson(data);
    final phase = getCurrentPhase(updatedOrder);

    state = state.copyWith(order: updatedOrder, phase: phase);
  }

  void setPhase(DeliveryPhase phase) {
    state = state.copyWith(phase: phase);
  }

  void updateOrder(DeliveryOrderModel order) {
    state = state.copyWith(order: order, phase: getCurrentPhase(order));
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>(
  (ref) {
    return DeliveryNotifier();
  },
);
