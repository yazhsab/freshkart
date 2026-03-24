import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/config/supabase_config.dart';
import 'package:freshkart_customer/core/models/order_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrackingState {
  final OrderModel? order;
  final double? agentLat;
  final double? agentLng;
  final String? agentName;
  final String? agentPhone;
  final int? estimatedMinutes;
  final bool isLoading;
  final String? error;

  const TrackingState({
    this.order,
    this.agentLat,
    this.agentLng,
    this.agentName,
    this.agentPhone,
    this.estimatedMinutes,
    this.isLoading = false,
    this.error,
  });

  TrackingState copyWith({
    OrderModel? order,
    double? agentLat,
    double? agentLng,
    String? agentName,
    String? agentPhone,
    int? estimatedMinutes,
    bool? isLoading,
    String? error,
  }) {
    return TrackingState(
      order: order ?? this.order,
      agentLat: agentLat ?? this.agentLat,
      agentLng: agentLng ?? this.agentLng,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrackingNotifier extends StateNotifier<TrackingState> {
  final String _orderId;
  final ApiClient _api;

  RealtimeChannel? _orderChannel;
  RealtimeChannel? _locationChannel;
  bool _disposed = false;

  TrackingNotifier(this._orderId, this._api)
    : super(const TrackingState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _fetchOrder();
    _subscribeToOrderUpdates();
    _subscribeToDeliveryLocation();
  }

  // ---- REST fetch ----

  Future<void> _fetchOrder() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _api.get(ApiEndpoints.orderById(_orderId));
      final data = response.data as Map<String, dynamic>;
      final order = OrderModel.fromJson(data['order'] as Map<String, dynamic>);

      // If the response contains tracking data, apply it.
      final tracking = data['tracking'] as Map<String, dynamic>?;

      state = state.copyWith(
        order: order,
        agentName: tracking?['agent_name'] as String?,
        agentPhone: tracking?['agent_phone'] as String?,
        agentLat: (tracking?['lat'] as num?)?.toDouble(),
        agentLng: (tracking?['lng'] as num?)?.toDouble(),
        estimatedMinutes: tracking?['estimated_minutes'] as int?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---- Supabase realtime: order status ----

  void _subscribeToOrderUpdates() {
    final client = SupabaseConfig.client;

    _orderChannel = client
        .channel('order-status-$_orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _orderId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty && !_disposed) {
              final updatedOrder = OrderModel.fromJson(newRecord);
              state = state.copyWith(order: updatedOrder);
            }
          },
        )
        .subscribe();
  }

  // ---- Supabase realtime: delivery location ----

  void _subscribeToDeliveryLocation() {
    final client = SupabaseConfig.client;

    _locationChannel = client
        .channel('delivery-loc-$_orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: _orderId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty && !_disposed) {
              state = state.copyWith(
                agentLat: (record['lat'] as num?)?.toDouble(),
                agentLng: (record['lng'] as num?)?.toDouble(),
                agentName: record['agent_name'] as String?,
                agentPhone: record['agent_phone'] as String?,
                estimatedMinutes: record['estimated_minutes'] as int?,
              );
            }
          },
        )
        .subscribe();
  }

  // ---- Cleanup ----

  @override
  void dispose() {
    _disposed = true;
    _orderChannel?.unsubscribe();
    _locationChannel?.unsubscribe();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider (family – one instance per orderId)
// ---------------------------------------------------------------------------

final trackingProvider =
    StateNotifierProvider.family<TrackingNotifier, TrackingState, String>(
      (ref, orderId) => TrackingNotifier(orderId, ApiClient()),
    );
