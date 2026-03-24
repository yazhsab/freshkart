import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DashboardState {
  final int ordersToday;
  final int pendingOrderCount;
  final double todayRevenue;
  final double weekRevenue;
  final double rating;
  final int totalRatings;
  final bool isShopOpen;
  final bool isLoading;
  final int lowStockCount;
  final String? error;

  const DashboardState({
    this.ordersToday = 0,
    this.pendingOrderCount = 0,
    this.todayRevenue = 0,
    this.weekRevenue = 0,
    this.rating = 0,
    this.totalRatings = 0,
    this.isShopOpen = false,
    this.isLoading = true,
    this.lowStockCount = 0,
    this.error,
  });

  DashboardState copyWith({
    int? ordersToday,
    int? pendingOrderCount,
    double? todayRevenue,
    double? weekRevenue,
    double? rating,
    int? totalRatings,
    bool? isShopOpen,
    bool? isLoading,
    int? lowStockCount,
    String? error,
  }) {
    return DashboardState(
      ordersToday: ordersToday ?? this.ordersToday,
      pendingOrderCount: pendingOrderCount ?? this.pendingOrderCount,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      weekRevenue: weekRevenue ?? this.weekRevenue,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      isShopOpen: isShopOpen ?? this.isShopOpen,
      isLoading: isLoading ?? this.isLoading,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Daily revenue helper
// ---------------------------------------------------------------------------

class DailyRevenue {
  final DateTime date;
  final double amount;

  const DailyRevenue({required this.date, required this.amount});
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Dio _dio;
  final Ref _ref;

  DashboardNotifier(this._dio, this._ref) : super(const DashboardState());

  // ---- public -----------------------------------------------------------

  Future<void> initialize(String vendorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _fetchTodayOrders(vendorId),
        _fetchProducts(),
        _fetchVendorProfile(),
        _fetchWeekRevenue(vendorId),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshStats() async {
    final vendorId = SupabaseConfig.currentUser?.id;
    if (vendorId == null) return;
    await initialize(vendorId);
  }

  Future<void> toggleShopOpen() async {
    final previous = state.isShopOpen;
    state = state.copyWith(isShopOpen: !previous);

    try {
      await _dio.patch(VendorApiEndpoints.vendorToggleOpen);

      if (!previous) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      // rollback
      state = state.copyWith(isShopOpen: previous);
    }
  }

  // ---- private fetchers -------------------------------------------------

  Future<void> _fetchTodayOrders(String vendorId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await _dio.get(
        VendorApiEndpoints.vendorOrders,
        queryParameters: {'date': today},
      );

      final orders = response.data['data'] as List? ?? [];
      int pending = 0;
      double revenue = 0;

      for (final o in orders) {
        if (o['status'] == 'pending') pending++;
        if (o['status'] != 'cancelled') {
          revenue += (o['total_amount'] ?? 0).toDouble();
        }
      }

      state = state.copyWith(
        ordersToday: orders.length,
        pendingOrderCount: pending,
        todayRevenue: revenue,
      );
    } catch (_) {}
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _dio.get(VendorApiEndpoints.products);
      final products = response.data['data'] as List? ?? [];

      int lowStock = 0;
      for (final p in products) {
        final stock = (p['stock_quantity'] ?? 0) as int;
        if (stock > 0 && stock <= VendorAppConfig.lowStockThreshold) {
          lowStock++;
        }
      }

      state = state.copyWith(lowStockCount: lowStock);
    } catch (_) {}
  }

  Future<void> _fetchVendorProfile() async {
    try {
      final response = await _dio.get(VendorApiEndpoints.vendorMe);
      final data = response.data['data'] ?? response.data;

      state = state.copyWith(
        rating: (data['rating'] ?? 0).toDouble(),
        totalRatings: (data['total_ratings'] ?? 0) as int,
        isShopOpen: data['is_open'] == true,
      );

      if (data['is_open'] == true) {
        await WakelockPlus.enable();
      }
    } catch (_) {}
  }

  Future<void> _fetchWeekRevenue(String vendorId) async {
    try {
      final response = await _dio.get(
        VendorApiEndpoints.earnings,
        queryParameters: {'period': 'week'},
      );
      final data = response.data['data'] ?? response.data;
      state = state.copyWith(weekRevenue: (data['total'] ?? 0).toDouble());
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:3000',
          ),
          headers: {
            'Authorization':
                'Bearer ${SupabaseConfig.currentSession?.accessToken ?? ''}',
          },
        ),
      );
      return DashboardNotifier(dio, ref);
    });

/// Realtime stream of pending orders from Supabase
final pendingOrdersStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, vendorId) {
      return SupabaseConfig.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('vendor_id', vendorId)
          .map((rows) => rows.where((r) => r['status'] == 'pending').toList());
    });

/// Weekly revenue list for chart
final weeklyRevenueProvider = FutureProvider<List<DailyRevenue>>((ref) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
      headers: {
        'Authorization':
            'Bearer ${SupabaseConfig.currentSession?.accessToken ?? ''}',
      },
    ),
  );

  try {
    final response = await dio.get(
      VendorApiEndpoints.earnings,
      queryParameters: {'period': 'week', 'group_by': 'day'},
    );
    final days = response.data['data']?['daily'] as List? ?? [];
    return days.map((d) {
      return DailyRevenue(
        date: DateTime.parse(d['date']),
        amount: (d['amount'] ?? 0).toDouble(),
      );
    }).toList();
  } catch (_) {
    // Return empty last-7-day placeholders
    return List.generate(7, (i) {
      return DailyRevenue(
        date: DateTime.now().subtract(Duration(days: 6 - i)),
        amount: 0,
      );
    });
  }
});
