import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_stats.dart';
import '../../../core/supabase/client.dart';
import '../../../core/utils/date_helpers.dart';

// ── Provider ─────────────────────────────────────────────────────

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final db = adminClient;
  final today = todayStart().toIso8601String();
  final sevenDaysAgoDate = daysAgo(6).toIso8601String();

  // ── Parallel queries via Future.wait ───────────────────────────

  final results = await Future.wait<dynamic>([
    // 0: orders today - count
    db
        .from('orders')
        .select('id')
        .gte('created_at', today),
    // 1: orders today - sum final_amount
    db.from('orders').select('final_amount').gte('created_at', today),
    // 2: orders today - by status
    db.from('orders').select('status').gte('created_at', today),
    // 3: active vendors count
    db
        .from('vendors')
        .select('id')
        .eq('is_approved', true)
        .eq('is_active', true),
    // 4: pending vendor approvals count
    db
        .from('vendors')
        .select('id')
        .eq('is_approved', false)
        .eq('is_active', true),
    // 5: delivery agents count
    db
        .from('profiles')
        .select('id')
        .eq('role', 'delivery_agent'),
    // 6: bookings today - count
    db
        .from('bookings')
        .select('id')
        .gte('created_at', today),
    // 7: bookings today - sum quoted_price
    db.from('bookings').select('quoted_price').gte('created_at', today),
    // 8: bookings today - by status
    db.from('bookings').select('status').gte('created_at', today),
    // 9: approved workers count
    db
        .from('workers')
        .select('id')
        .eq('is_approved', true)
        .eq('is_available', true),
    // 10: pending BGV workers count
    db
        .from('workers')
        .select('id')
        .eq('bgv_status', 'pending'),
    // 11: last 20 notifications for activity feed
    db
        .from('notifications_log')
        .select()
        .order('sent_at', ascending: false)
        .limit(20),
    // 12: orders last 7 days
    db.from('orders').select('created_at').gte('created_at', sevenDaysAgoDate),
    // 13: bookings last 7 days
    db
        .from('bookings')
        .select('created_at')
        .gte('created_at', sevenDaysAgoDate),
    // 14: failed payments count
    db
        .from('payments')
        .select('id')
        .eq('status', 'failed'),
    // 15: unassigned bookings count
    db
        .from('bookings')
        .select('id')
        .eq('status', 'pending'),
    // 16: low stock products count
    db
        .from('products')
        .select('id')
        .lte('stock_quantity', 5)
        .eq('is_available', true),
    // 17: delivery agents online (active)
    db
        .from('profiles')
        .select('id')
        .eq('role', 'delivery_agent')
        .eq('is_active', true),
  ]);

  // ── Extract counts ─────────────────────────────────────────────

  int countOf(dynamic result) {
    if (result is List) return result.length;
    return 0;
  }

  final ordersToday = countOf(results[0]);
  final activeVendors = countOf(results[3]);
  final pendingVendors = countOf(results[4]);
  final totalDeliveryAgents = countOf(results[5]);
  final bookingsToday = countOf(results[6]);
  final activeWorkers = countOf(results[9]);
  final pendingBgvWorkers = countOf(results[10]);
  final failedPayments = countOf(results[14]);
  final unassignedBookings = countOf(results[15]);
  final lowStockProducts = countOf(results[16]);
  final deliveryAgentsOnline = countOf(results[17]);

  // ── Extract revenue sums ───────────────────────────────────────

  double sumField(dynamic result, String field) {
    final rows = result as List<dynamic>;
    var total = 0.0;
    for (final row in rows) {
      final val = (row as Map<String, dynamic>)[field];
      if (val != null) total += (val as num).toDouble();
    }
    return total;
  }

  final groceryRevenueToday = sumField(results[1], 'final_amount');
  final serviceRevenueToday = sumField(results[7], 'quoted_price');

  // ── Extract activity feed ──────────────────────────────────────

  final activityRaw = results[11] as List<dynamic>;
  final activityFeed = activityRaw
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  // ── Build 7 day counts ─────────────────────────────────────────

  List<DailyCount> groupByDay(dynamic result) {
    final rows = result as List<dynamic>;
    final dayCounts = <String, int>{};

    for (var i = 6; i >= 0; i--) {
      final d = daysAgo(i);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dayCounts[key] = 0;
    }

    for (final row in rows) {
      final dt = DateTime.tryParse(
        (row as Map<String, dynamic>)['created_at']?.toString() ?? '',
      );
      if (dt != null) {
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        if (dayCounts.containsKey(key)) {
          dayCounts[key] = dayCounts[key]! + 1;
        }
      }
    }

    return dayCounts.entries.map((e) {
      final parts = e.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DailyCount(date: date, count: e.value);
    }).toList();
  }

  final ordersLast7Days = groupByDay(results[12]);
  final bookingsLast7Days = groupByDay(results[13]);

  // ── Calculate alert count ──────────────────────────────────────

  final alertCount =
      failedPayments + pendingVendors + unassignedBookings + lowStockProducts;

  // ── Compute GMV and commission ─────────────────────────────────

  final totalGmv = groceryRevenueToday + serviceRevenueToday;
  final platformCommission =
      (groceryRevenueToday * 0.10) + (serviceRevenueToday * 0.20);

  return DashboardStats(
    ordersToday: ordersToday,
    groceryRevenueToday: groceryRevenueToday,
    activeVendors: activeVendors,
    pendingVendors: pendingVendors,
    deliveryAgentsOnline: deliveryAgentsOnline,
    bookingsToday: bookingsToday,
    serviceRevenueToday: serviceRevenueToday,
    activeWorkers: activeWorkers,
    pendingBgvWorkers: pendingBgvWorkers,
    alertCount: alertCount,
    totalGmvToday: totalGmv,
    platformCommissionToday: platformCommission,
    ordersLast7Days: ordersLast7Days,
    bookingsLast7Days: bookingsLast7Days,
    activityFeed: activityFeed,
    failedPayments: failedPayments,
    pendingVendorApprovals: pendingVendors,
    unassignedBookings: unassignedBookings,
    lowStockProducts: lowStockProducts,
  );
});
