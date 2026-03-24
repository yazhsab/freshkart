import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/config/supabase_config.dart';
import 'package:freshkart_delivery/core/location/location_service.dart';
import 'package:freshkart_delivery/core/location/location_tracker.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HomeState {
  final bool isOnline;
  final DeliveryOrderModel? activeDelivery;
  final List<DeliveryOrderModel> availableOrders;
  final double todayEarnings;
  final int todayDeliveries;
  final double todayDistanceKm;
  final int batteryLevel;
  final bool isLoading;
  final String? error;
  final DateTime? onlineSince;

  const HomeState({
    this.isOnline = false,
    this.activeDelivery,
    this.availableOrders = const [],
    this.todayEarnings = 0.0,
    this.todayDeliveries = 0,
    this.todayDistanceKm = 0.0,
    this.batteryLevel = 100,
    this.isLoading = true,
    this.error,
    this.onlineSince,
  });

  HomeState copyWith({
    bool? isOnline,
    DeliveryOrderModel? activeDelivery,
    bool clearActiveDelivery = false,
    List<DeliveryOrderModel>? availableOrders,
    double? todayEarnings,
    int? todayDeliveries,
    double? todayDistanceKm,
    int? batteryLevel,
    bool? isLoading,
    String? error,
    DateTime? onlineSince,
    bool clearOnlineSince = false,
  }) {
    return HomeState(
      isOnline: isOnline ?? this.isOnline,
      activeDelivery: clearActiveDelivery
          ? null
          : (activeDelivery ?? this.activeDelivery),
      availableOrders: availableOrders ?? this.availableOrders,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      todayDistanceKm: todayDistanceKm ?? this.todayDistanceKm,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      onlineSince: clearOnlineSince ? null : (onlineSince ?? this.onlineSince),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;
  final Battery _battery = Battery();
  Timer? _batteryTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  HomeNotifier(this._ref) : super(const HomeState());

  // ---- public -------------------------------------------------------------

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final savedOnline = LocalStorage.isOnline;
      state = state.copyWith(isOnline: savedOnline);

      await Future.wait([_fetchActiveDelivery(), fetchTodayEarnings()]);

      await startBatteryMonitoring();

      if (savedOnline) {
        state = state.copyWith(onlineSince: DateTime.now());
        _ref.read(locationTrackerProvider.notifier).startTracking(null);
        _listenForAvailableOrders();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleOnline() async {
    if (state.isOnline) {
      // Going offline
      if (state.activeDelivery != null) {
        state = state.copyWith(
          error: 'Complete your active delivery before going offline',
        );
        return;
      }

      final previousOnline = state.isOnline;
      state = state.copyWith(
        isOnline: false,
        clearOnlineSince: true,
        availableOrders: [],
      );

      try {
        await ApiClient.instance.patch(ApiEndpoints.toggleOnline);
        await LocalStorage.setIsOnline(false);
        _ref.read(locationTrackerProvider.notifier).stopTracking();
        _ordersSubscription?.cancel();
        _ordersSubscription = null;
      } catch (e) {
        state = state.copyWith(isOnline: previousOnline, error: e.toString());
      }
    } else {
      // Going online
      final hasPermission = await LocationService.initialize();
      if (!hasPermission) {
        state = state.copyWith(
          error: 'Location permission is required to go online',
        );
        return;
      }

      final batteryLevel = await _battery.batteryLevel;
      if (batteryLevel <= 15) {
        state = state.copyWith(
          error:
              'Battery too low ($batteryLevel%). Charge above 15% to go online.',
          batteryLevel: batteryLevel,
        );
        return;
      }

      final previousOnline = state.isOnline;
      state = state.copyWith(isOnline: true, onlineSince: DateTime.now());

      try {
        await ApiClient.instance.patch(ApiEndpoints.toggleOnline);
        await LocalStorage.setIsOnline(true);
        await _ref.read(locationTrackerProvider.notifier).startTracking(null);
        _listenForAvailableOrders();
      } catch (e) {
        state = state.copyWith(
          isOnline: previousOnline,
          clearOnlineSince: true,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.acceptDelivery(orderId),
      );

      final data = response.data['data'] ?? response.data;
      final order = DeliveryOrderModel.fromJson(
        data is Map<String, dynamic>
            ? data
            : {'id': orderId, 'status': 'assigned'},
      );

      // Remove from available and set as active
      final updatedAvailable = state.availableOrders
          .where((o) => o.id != orderId)
          .toList();

      state = state.copyWith(
        activeDelivery: order,
        availableOrders: updatedAvailable,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchTodayEarnings() async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.earningsSummary,
        queryParameters: {'period': 'today'},
      );

      final data = response.data['data'] ?? response.data;
      state = state.copyWith(
        todayEarnings: (data['total_earnings'] as num?)?.toDouble() ?? 0.0,
        todayDeliveries: (data['delivery_count'] as num?)?.toInt() ?? 0,
        todayDistanceKm: (data['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (_) {
      // Silently fail - earnings will show 0
    }
  }

  Future<void> startBatteryMonitoring() async {
    try {
      final level = await _battery.batteryLevel;
      state = state.copyWith(batteryLevel: level);
    } catch (_) {}

    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        final level = await _battery.batteryLevel;
        state = state.copyWith(batteryLevel: level);
      } catch (_) {}
    });
  }

  Future<void> refresh() async {
    await Future.wait([_fetchActiveDelivery(), fetchTodayEarnings()]);
  }

  // ---- private ------------------------------------------------------------

  void _listenForAvailableOrders() {
    _ordersSubscription?.cancel();

    _ordersSubscription = SupabaseConfig.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'ready')
        .map(
          (rows) => rows.where((r) => r['delivery_agent_id'] == null).toList(),
        )
        .listen((rows) {
          final orders = rows
              .map((r) => DeliveryOrderModel.fromJson(r))
              .toList();

          // Sort newest first
          orders.sort((a, b) {
            final aTime = a.assignedAt ?? DateTime(2000);
            final bTime = b.assignedAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          state = state.copyWith(availableOrders: orders);
        }, onError: (_) {});
  }

  Future<void> _fetchActiveDelivery() async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.activeDelivery,
      );
      final data = response.data['data'] ?? response.data;

      if (data != null && data is Map<String, dynamic> && data.isNotEmpty) {
        state = state.copyWith(
          activeDelivery: DeliveryOrderModel.fromJson(data),
        );
      } else {
        state = state.copyWith(clearActiveDelivery: true);
      }
    } catch (_) {
      state = state.copyWith(clearActiveDelivery: true);
    }
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});
