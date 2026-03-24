import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_vendor/core/api/api_endpoints.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/core/models/order_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class OrdersState {
  final List<OrderModel> orders;
  final String filter;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const OrdersState({
    this.orders = const [],
    this.filter = 'all',
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  List<OrderModel> get pendingOrders =>
      orders.where((o) => o.isPending).toList();

  List<OrderModel> get activeOrders => orders.where((o) => o.isActive).toList();

  List<OrderModel> get readyOrders => orders.where((o) => o.isReady).toList();

  List<OrderModel> get doneOrders => orders.where((o) => o.isDone).toList();

  int get pendingCount => pendingOrders.length;
  int get activeCount => activeOrders.length;
  int get readyCount => readyOrders.length;
  int get doneCount => doneOrders.length;

  OrdersState copyWith({
    List<OrderModel>? orders,
    String? filter,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class OrdersNotifier extends StateNotifier<OrdersState> {
  final Dio _dio;
  final Ref _ref;

  OrdersNotifier(this._dio, this._ref) : super(const OrdersState());

  // ---- public -------------------------------------------------------------

  Future<void> fetchOrders(
    String vendorId, {
    String? filter,
    int page = 1,
  }) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': 20};

      if (filter != null && filter != 'all') {
        switch (filter) {
          case 'pending':
            queryParams['status'] = 'pending';
            break;
          case 'active':
            queryParams['status'] = 'confirmed,packing';
            break;
          case 'ready':
            queryParams['status'] = 'ready';
            break;
          case 'completed':
            queryParams['status'] = 'delivered,cancelled';
            break;
        }
      }

      final response = await _dio.get(
        VendorApiEndpoints.vendorOrders,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      final List<dynamic> ordersJson = data is List
          ? data
          : (data?['orders'] as List? ?? []);

      final newOrders = ordersJson
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final hasMore = newOrders.length >= 20;

      if (page == 1) {
        state = state.copyWith(
          orders: newOrders,
          filter: filter ?? state.filter,
          isLoading: false,
          page: 1,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          orders: [...state.orders, ...newOrders],
          isLoading: false,
          page: page,
          hasMore: hasMore,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Failed to fetch orders',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancelReason,
  }) async {
    try {
      final body = <String, dynamic>{'status': newStatus};
      if (cancelReason != null) {
        body['cancel_reason'] = cancelReason;
      }

      await _dio.patch(VendorApiEndpoints.orderStatus(orderId), data: body);

      // Update local state
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(
            status: newStatus,
            vendorConfirmedAt: newStatus == 'confirmed' ? DateTime.now() : null,
            packedAt: newStatus == 'ready' ? DateTime.now() : null,
            cancelReason: cancelReason,
            cancelledBy: newStatus == 'cancelled' ? 'vendor' : null,
            cancelledAt: newStatus == 'cancelled' ? DateTime.now() : null,
          );
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error:
            e.response?.data?['message']?.toString() ??
            'Failed to update order status',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void updateFromRealtime(List<Map<String, dynamic>> realtimeData) {
    final realtimeOrders = realtimeData
        .map((e) => OrderModel.fromJson(e))
        .toList();

    final existingIds = state.orders.map((o) => o.id).toSet();
    final updatedOrders = <OrderModel>[];

    // Update existing orders with realtime data
    for (final order in state.orders) {
      final realtimeMatch = realtimeOrders
          .where((r) => r.id == order.id)
          .firstOrNull;
      if (realtimeMatch != null) {
        updatedOrders.add(realtimeMatch);
      } else {
        updatedOrders.add(order);
      }
    }

    // Add new orders from realtime that don't exist locally
    for (final rtOrder in realtimeOrders) {
      if (!existingIds.contains(rtOrder.id)) {
        updatedOrders.insert(0, rtOrder);
      }
    }

    state = state.copyWith(orders: updatedOrders);
  }

  Future<void> refreshOrders() async {
    final vendorId = SupabaseConfig.currentUser?.id;
    if (vendorId == null) return;
    await fetchOrders(vendorId, filter: state.filter, page: 1);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    final vendorId = SupabaseConfig.currentUser?.id;
    if (vendorId == null) return;
    await fetchOrders(vendorId, filter: state.filter, page: state.page + 1);
  }

  void setFilter(String filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
    refreshOrders();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
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
  return OrdersNotifier(dio, ref);
});

/// Stream provider for realtime order updates via Supabase
final ordersRealtimeProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, vendorId) {
      return SupabaseConfig.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('vendor_id', vendorId);
    });
