import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── Period selection ──────────────────────────────────────────────

final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodNotifier, String>(
  AnalyticsPeriodNotifier.new,
);

class AnalyticsPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'today';
  void set(String period) => state = period;
}

// ── Analytics data model ─────────────────────────────────────────

class AnalyticsData {
  final int totalOrders;
  final double groceryRevenue;
  final double groceryAvgOrder;
  final int groceryDelivered;
  final int groceryCancelled;
  final int totalBookings;
  final double serviceRevenue;
  final double serviceAvgBooking;
  final int serviceCompleted;
  final int serviceCancelled;
  final double combinedGMV;
  final List<DailyRevenue> dailyGroceryRevenue;
  final List<DailyRevenue> dailyServiceRevenue;
  final List<HourlyOrders> ordersByHour;
  final List<CategoryShare> categoryShares;
  final List<TopVendor> topVendors;

  AnalyticsData({
    required this.totalOrders,
    required this.groceryRevenue,
    required this.groceryAvgOrder,
    required this.groceryDelivered,
    required this.groceryCancelled,
    required this.totalBookings,
    required this.serviceRevenue,
    required this.serviceAvgBooking,
    required this.serviceCompleted,
    required this.serviceCancelled,
    required this.combinedGMV,
    required this.dailyGroceryRevenue,
    required this.dailyServiceRevenue,
    required this.ordersByHour,
    required this.categoryShares,
    required this.topVendors,
  });
}

class DailyRevenue {
  final DateTime date;
  final double amount;
  DailyRevenue({required this.date, required this.amount});
}

class HourlyOrders {
  final int hour;
  final int count;
  HourlyOrders({required this.hour, required this.count});
}

class CategoryShare {
  final String name;
  final int count;
  final double revenue;
  CategoryShare(
      {required this.name, required this.count, required this.revenue});
}

class TopVendor {
  final String name;
  final double revenue;
  final int orders;
  TopVendor(
      {required this.name, required this.revenue, required this.orders});
}

// ── Analytics provider ───────────────────────────────────────────

final analyticsProvider =
    FutureProvider.family<AnalyticsData, String>((ref, period) async {
  final now = DateTime.now();
  final DateTime from;
  switch (period) {
    case '7days':
      from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
    case '30days':
      from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 30));
    case '3months':
      from = DateTime(now.year, now.month - 3, now.day);
    default: // today
      from = DateTime(now.year, now.month, now.day);
  }

  final fromStr = from.toIso8601String();

  // Run grocery and service queries in parallel
  final results = await Future.wait([
    // 0: orders
    adminClient
        .from('orders')
        .select('id, final_amount, status, created_at, vendor_id')
        .gte('created_at', fromStr),
    // 1: bookings
    adminClient
        .from('bookings')
        .select(
            'id, final_price, booking_fee, status, created_at, service_category_id')
        .gte('created_at', fromStr),
    // 2: service categories
    adminClient.from('service_categories').select('id, name'),
    // 3: vendors
    adminClient.from('vendors').select('id, shop_name'),
  ]);

  final orders = results[0] as List;
  final bookings = results[1] as List;
  final categories = results[2] as List;
  final vendors = results[3] as List;

  // Category map
  final catMap = <String, String>{};
  for (final c in categories) {
    catMap[c['id'] as String] = c['name'] as String;
  }

  // Vendor map
  final vendorMap = <String, String>{};
  for (final v in vendors) {
    vendorMap[v['id'] as String] = v['shop_name'] as String;
  }

  // ── Grocery stats ──────────────────────────────────────────
  double groceryRevenue = 0;
  int groceryDelivered = 0;
  int groceryCancelled = 0;
  final dailyGroceryMap = <String, double>{};
  final hourlyMap = <int, int>{};
  final vendorRevMap = <String, double>{};
  final vendorOrderMap = <String, int>{};

  for (final o in orders) {
    final amount = ((o['final_amount'] as num?) ?? 0).toDouble();
    final status = o['status'] as String? ?? '';
    final createdAt = DateTime.tryParse(o['created_at'] as String? ?? '');
    final vendorId = o['vendor_id'] as String? ?? '';

    if (status == 'delivered') {
      groceryRevenue += amount;
      groceryDelivered++;
    }
    if (status == 'cancelled') groceryCancelled++;

    // Daily revenue (delivered only)
    if (status == 'delivered' && createdAt != null) {
      final dayKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      dailyGroceryMap[dayKey] = (dailyGroceryMap[dayKey] ?? 0) + amount;
    }

    // Orders by hour
    if (createdAt != null) {
      hourlyMap[createdAt.hour] = (hourlyMap[createdAt.hour] ?? 0) + 1;
    }

    // Top vendors
    if (vendorId.isNotEmpty && status == 'delivered') {
      vendorRevMap[vendorId] = (vendorRevMap[vendorId] ?? 0) + amount;
      vendorOrderMap[vendorId] = (vendorOrderMap[vendorId] ?? 0) + 1;
    }
  }

  // ── Service stats ──────────────────────────────────────────
  double serviceRevenue = 0;
  int serviceCompleted = 0;
  int serviceCancelled = 0;
  final dailyServiceMap = <String, double>{};
  final catCountMap = <String, int>{};
  final catRevMap = <String, double>{};

  for (final b in bookings) {
    final price = ((b['final_price'] as num?) ?? 0).toDouble();
    final fee = ((b['booking_fee'] as num?) ?? 0).toDouble();
    final status = b['status'] as String? ?? '';
    final createdAt = DateTime.tryParse(b['created_at'] as String? ?? '');
    final catId = b['service_category_id'] as String? ?? '';

    if (status == 'completed') {
      serviceRevenue += price + fee;
      serviceCompleted++;
    }
    if (status == 'cancelled') serviceCancelled++;

    // Daily service revenue
    if (status == 'completed' && createdAt != null) {
      final dayKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      dailyServiceMap[dayKey] =
          (dailyServiceMap[dayKey] ?? 0) + price + fee;
    }

    // Category shares
    if (catId.isNotEmpty) {
      catCountMap[catId] = (catCountMap[catId] ?? 0) + 1;
      if (status == 'completed') {
        catRevMap[catId] = (catRevMap[catId] ?? 0) + price + fee;
      }
    }
  }

  // Build daily revenue lists
  final allDays = <String>{...dailyGroceryMap.keys, ...dailyServiceMap.keys};
  final sortedDays = allDays.toList()..sort();

  final dailyGroceryRevenue = sortedDays
      .map((d) => DailyRevenue(
          date: DateTime.parse(d), amount: dailyGroceryMap[d] ?? 0))
      .toList();

  final dailyServiceRevenue = sortedDays
      .map((d) => DailyRevenue(
          date: DateTime.parse(d), amount: dailyServiceMap[d] ?? 0))
      .toList();

  // Hourly orders (0..23)
  final ordersByHour = List.generate(
      24, (h) => HourlyOrders(hour: h, count: hourlyMap[h] ?? 0));

  // Category shares
  final categoryShares = catCountMap.entries.map((e) {
    return CategoryShare(
      name: catMap[e.key] ?? 'Unknown',
      count: e.value,
      revenue: catRevMap[e.key] ?? 0,
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  // Top 5 vendors
  final vendorEntries = vendorRevMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topVendors = vendorEntries.take(5).map((e) {
    return TopVendor(
      name: vendorMap[e.key] ?? 'Unknown',
      revenue: e.value,
      orders: vendorOrderMap[e.key] ?? 0,
    );
  }).toList();

  final totalOrders = orders.length;
  final totalBookings = bookings.length;

  return AnalyticsData(
    totalOrders: totalOrders,
    groceryRevenue: groceryRevenue,
    groceryAvgOrder:
        groceryDelivered > 0 ? groceryRevenue / groceryDelivered : 0,
    groceryDelivered: groceryDelivered,
    groceryCancelled: groceryCancelled,
    totalBookings: totalBookings,
    serviceRevenue: serviceRevenue,
    serviceAvgBooking:
        serviceCompleted > 0 ? serviceRevenue / serviceCompleted : 0,
    serviceCompleted: serviceCompleted,
    serviceCancelled: serviceCancelled,
    combinedGMV: groceryRevenue + serviceRevenue,
    dailyGroceryRevenue: dailyGroceryRevenue,
    dailyServiceRevenue: dailyServiceRevenue,
    ordersByHour: ordersByHour,
    categoryShares: categoryShares,
    topVendors: topVendors,
  );
});
