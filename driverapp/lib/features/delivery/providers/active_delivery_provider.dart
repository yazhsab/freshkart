import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/config/supabase_config.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/location/location_tracker.dart';

class ActiveDeliveryState {
  final DeliveryOrderModel? order;
  final bool isLoading;
  final String? error;

  const ActiveDeliveryState({this.order, this.isLoading = false, this.error});

  ActiveDeliveryState copyWith({
    DeliveryOrderModel? order,
    bool? isLoading,
    String? error,
    bool clearOrder = false,
  }) {
    return ActiveDeliveryState(
      order: clearOrder ? null : (order ?? this.order),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ActiveDeliveryNotifier extends StateNotifier<ActiveDeliveryState> {
  final Ref ref;
  RealtimeChannel? _realtimeChannel;

  ActiveDeliveryNotifier(this.ref) : super(const ActiveDeliveryState());

  Future<void> fetchActiveDelivery() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.activeDelivery,
      );
      final data = response.data as Map<String, dynamic>;

      if (data['order'] != null) {
        final order = DeliveryOrderModel.fromJson(
          data['order'] as Map<String, dynamic>,
        );
        state = state.copyWith(order: order, isLoading: false);
        subscribeToOrder(order.id);
      } else {
        state = state.copyWith(isLoading: false, clearOrder: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> confirmPickup(String orderId, String vendorOtp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.pickupConfirm(orderId),
        data: {'otp': vendorOtp},
      );

      final data = response.data as Map<String, dynamic>;
      final updatedOrder = state.order?.copyWith(
        status: 'picked_up',
        pickedUpAt: DateTime.now(),
      );

      if (data['order'] != null) {
        final serverOrder = DeliveryOrderModel.fromJson(
          data['order'] as Map<String, dynamic>,
        );
        state = state.copyWith(order: serverOrder, isLoading: false);
      } else if (updatedOrder != null) {
        state = state.copyWith(order: updatedOrder, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return true;
    } catch (e) {
      String errorMsg = 'Failed to verify OTP';
      if (e.toString().contains('invalid') || e.toString().contains('wrong')) {
        errorMsg = 'Wrong OTP. Ask vendor to check.';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> confirmDelivery(String orderId, String customerOtp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.deliveryConfirm(orderId),
        data: {'otp': customerOtp},
      );

      // Stop location tracking on successful delivery
      ref.read(locationTrackerProvider.notifier).stopTracking();

      final data = response.data as Map<String, dynamic>;
      if (data['order'] != null) {
        final serverOrder = DeliveryOrderModel.fromJson(
          data['order'] as Map<String, dynamic>,
        );
        state = state.copyWith(order: serverOrder, isLoading: false);
      } else {
        final updatedOrder = state.order?.copyWith(
          status: 'delivered',
          deliveredAt: DateTime.now(),
        );
        if (updatedOrder != null) {
          state = state.copyWith(order: updatedOrder, isLoading: false);
        }
      }

      _unsubscribeFromOrder();
      return true;
    } catch (e) {
      String errorMsg = 'Failed to verify OTP';
      if (e.toString().contains('invalid') || e.toString().contains('wrong')) {
        errorMsg = 'Wrong OTP. Ask customer to check.';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  void subscribeToOrder(String orderId) {
    _unsubscribeFromOrder();

    _realtimeChannel = SupabaseConfig.client
        .channel('delivery_order_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData.isNotEmpty) {
              _handleRealtimeUpdate(newData);
            }
          },
        )
        .subscribe();
  }

  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    final newStatus = data['status'] as String?;

    if (newStatus == 'cancelled') {
      ref.read(locationTrackerProvider.notifier).stopTracking();
      state = state.copyWith(
        order: state.order?.copyWith(status: 'cancelled'),
        error: 'Order has been cancelled',
      );
      _unsubscribeFromOrder();
      return;
    }

    if (state.order != null) {
      final updatedOrder = DeliveryOrderModel.fromJson({
        ...state.order!.toJson(),
        ...data,
      });
      state = state.copyWith(order: updatedOrder);
    }
  }

  void _unsubscribeFromOrder() {
    if (_realtimeChannel != null) {
      SupabaseConfig.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _unsubscribeFromOrder();
    super.dispose();
  }
}

final activeDeliveryProvider =
    StateNotifierProvider<ActiveDeliveryNotifier, ActiveDeliveryState>((ref) {
      return ActiveDeliveryNotifier(ref);
    });
