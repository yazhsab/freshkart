import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';
import '../../../core/models/order.dart';

// ── State ────────────────────────────────────────────────────────

class OrderListState {
  const OrderListState({
    this.orders = const [],
    this.statusFilter = 'All',
    this.dateRange,
    this.paymentFilter = 'All',
    this.searchQuery = '',
    this.isLoading = false,
    this.page = 1,
    this.totalPages = 1,
  });

  final List<Order> orders;
  final String statusFilter;
  final DateTimeRange? dateRange;
  final String paymentFilter;
  final String searchQuery;
  final bool isLoading;
  final int page;
  final int totalPages;

  OrderListState copyWith({
    List<Order>? orders,
    String? statusFilter,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? paymentFilter,
    String? searchQuery,
    bool? isLoading,
    int? page,
    int? totalPages,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      statusFilter: statusFilter ?? this.statusFilter,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      paymentFilter: paymentFilter ?? this.paymentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  List<Order> get filteredOrders {
    var result = orders;

    // Status filter
    if (statusFilter != 'All') {
      final statusKey = statusFilter.toLowerCase().replaceAll(' ', '_');
      result = result.where((o) => o.status == statusKey).toList();
    }

    // Payment filter
    if (paymentFilter != 'All') {
      final payKey = paymentFilter.toLowerCase();
      result = result.where((o) => o.paymentMethod == payKey).toList();
    }

    // Date range
    if (dateRange != null) {
      result = result.where((o) {
        if (o.createdAt == null) return false;
        return o.createdAt!.isAfter(dateRange!.start) &&
            o.createdAt!
                .isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((o) {
        return (o.orderNumber?.toLowerCase().contains(q) ?? false) ||
            (o.customer?.fullName?.toLowerCase().contains(q) ?? false) ||
            (o.customer?.phone.contains(q) ?? false) ||
            (o.vendor?.shopName.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  // Summary stats
  int get totalCount => filteredOrders.length;
  double get totalAmount =>
      filteredOrders.fold(0.0, (sum, o) => sum + o.finalAmount);
  int get codCount =>
      filteredOrders.where((o) => o.paymentMethod == 'cod').length;
  int get onlineCount =>
      filteredOrders.where((o) => o.paymentMethod == 'online').length;
}

// ── Provider ─────────────────────────────────────────────────────

const _pageSize = 50;

final orderListProvider =
    NotifierProvider<OrderListNotifier, OrderListState>(
  OrderListNotifier.new,
);

class OrderListNotifier extends Notifier<OrderListState> {
  @override
  OrderListState build() {
    loadOrders();
    return const OrderListState(isLoading: true);
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      // Count total
      final countResult = await adminClient
          .from('orders')
          .select('id');
      final total = (countResult as List).length;
      final totalPages = (total / _pageSize).ceil().clamp(1, 9999);

      final offset = (state.page - 1) * _pageSize;

      final rows = await adminClient
          .from('orders')
          .select('''
            *,
            customer:profiles!orders_customer_id_fkey(id, full_name, phone, email, avatar_url),
            vendors(id, shop_name, shop_name_tamil, owner_id),
            order_items(id, order_id, product_id, product_name, product_image_url, unit, quantity, unit_price, total_price)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final orders = rows
          .map((row) => Order.fromJson(row as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        totalPages: totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter, page: 1);
  }

  void setPaymentFilter(String filter) {
    state = state.copyWith(paymentFilter: filter);
  }

  void setDateRange(DateTimeRange? range) {
    if (range == null) {
      state = state.copyWith(clearDateRange: true);
    } else {
      state = state.copyWith(dateRange: range);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
    loadOrders();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? reason,
  }) async {
    final updates = <String, dynamic>{'status': newStatus};

    switch (newStatus) {
      case 'confirmed':
        updates['vendor_confirmed_at'] = DateTime.now().toIso8601String();
      case 'packed':
        updates['packed_at'] = DateTime.now().toIso8601String();
      case 'picked_up':
        updates['picked_up_at'] = DateTime.now().toIso8601String();
      case 'delivered':
        updates['delivered_at'] = DateTime.now().toIso8601String();
        updates['payment_status'] = 'paid';
      case 'cancelled':
        updates['cancelled_by'] = 'admin';
        if (reason != null) updates['cancel_reason'] = reason;
      case 'refunded':
        updates['payment_status'] = 'refunded';
    }

    await adminClient
        .from('orders')
        .update(updates)
        .eq('id', orderId);

    // Notify customer
    final order = await adminClient
        .from('orders')
        .select('customer_id, order_number')
        .eq('id', orderId)
        .single();

    final statusLabel = newStatus.replaceAll('_', ' ');
    await adminClient.from('notifications_log').insert({
      'user_id': order['customer_id'],
      'ref_type': 'order',
      'ref_id': orderId,
      'title': 'Order ${statusLabel[0].toUpperCase()}${statusLabel.substring(1)}',
      'body': 'Your order #${order['order_number']} has been $statusLabel.',
      'type': 'order',
    });

    await loadOrders();
  }

  Future<void> assignAgent(String orderId, String agentId) async {
    await adminClient.from('orders').update({
      'delivery_agent_id': agentId,
    }).eq('id', orderId);

    await adminClient.from('notifications_log').insert({
      'user_id': agentId,
      'ref_type': 'order',
      'ref_id': orderId,
      'title': 'New Delivery Assignment',
      'body': 'You have been assigned a new delivery order.',
      'type': 'order',
    });

    await loadOrders();
  }
}

// ── Selected order ───────────────────────────────────────────────

final selectedOrderProvider =
    NotifierProvider<SelectedOrderNotifier, Order?>(
  SelectedOrderNotifier.new,
);

class SelectedOrderNotifier extends Notifier<Order?> {
  @override
  Order? build() => null;
  void select(Order? order) => state = order;
  void clear() => state = null;
}

// ── Available delivery agents ────────────────────────────────────

final availableAgentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await adminClient
      .from('profiles')
      .select('id, full_name, phone')
      .eq('role', 'delivery_agent')
      .eq('is_active', true)
      .order('full_name');
});
