import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/order_model.dart';
import 'package:freshkart_customer/core/models/product_model.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class OrdersState {
  final List<OrderModel> activeOrders;
  final List<OrderModel> pastOrders;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.activeOrders = const [],
    this.pastOrders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<OrderModel>? activeOrders,
    List<OrderModel>? pastOrders,
    bool? isLoading,
    String? error,
  }) {
    return OrdersState(
      activeOrders: activeOrders ?? this.activeOrders,
      pastOrders: pastOrders ?? this.pastOrders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Active status set
// ---------------------------------------------------------------------------

const _activeStatuses = {
  'pending',
  'confirmed',
  'packing',
  'ready',
  'picked_up',
};

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class OrdersNotifier extends StateNotifier<OrdersState> {
  final ApiClient _api;
  final Ref _ref;

  OrdersNotifier(this._api, this._ref) : super(const OrdersState());

  /// Fetches all orders and splits them into active / past buckets.
  Future<void> fetchOrders() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _api.get(ApiEndpoints.myOrders);
      final data = response.data as Map<String, dynamic>;
      final list = (data['orders'] as List<dynamic>)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final active = <OrderModel>[];
      final past = <OrderModel>[];

      for (final order in list) {
        if (_activeStatuses.contains(order.status)) {
          active.add(order);
        } else {
          past.add(order);
        }
      }

      state = state.copyWith(
        activeOrders: active,
        pastOrders: past,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cancels an order by its [orderId].
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _api.post(ApiEndpoints.cancelOrder(orderId));
      await fetchOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Re-orders by loading items from a past order into the cart.
  Future<void> reorder(String orderId) async {
    try {
      final response = await _api.get(ApiEndpoints.orderById(orderId));
      final data = response.data as Map<String, dynamic>;
      final order = OrderModel.fromJson(data['order'] as Map<String, dynamic>);

      final cartNotifier = _ref.read(cartProvider.notifier);
      cartNotifier.clearCart();

      for (final item in order.items) {
        final product = ProductModel(
          id: item.productId,
          vendorId: order.vendorId,
          categoryId: '',
          name: item.productName,
          imageUrl: item.productImageUrl,
          price: item.unitPrice,
          mrp: item.unitPrice,
          unit: item.unit,
          stockQuantity: 99,
          isAvailable: true,
        );
        cartNotifier.addItem(product, qty: item.quantity);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  return OrdersNotifier(ApiClient(), ref);
});
