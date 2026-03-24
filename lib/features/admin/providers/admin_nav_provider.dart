import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routes.dart';

// ── Current route provider ───────────────────────────────────────
class AdminNavNotifier extends Notifier<String> {
  @override
  String build() => kAdminDashboard;

  void go(String route) => state = route;
}

final adminNavProvider =
    NotifierProvider<AdminNavNotifier, String>(AdminNavNotifier.new);

// ── Human-readable page titles ───────────────────────────────────
const pageTitles = <String, String>{
  kAdminDashboard: 'Dashboard',
  kAdminAnalytics: 'Analytics',
  kAdminCustomers: 'Customers',
  kAdminVendors: 'Vendors',
  kAdminOrders: 'Orders',
  kAdminProducts: 'Products',
  kAdminAgents: 'Delivery Agents',
  kAdminVendorPayouts: 'Vendor Payouts',
  kAdminWorkers: 'Workers',
  kAdminBookings: 'Bookings',
  kAdminServiceCatalog: 'Service Catalog',
  kAdminWorkerPayouts: 'Worker Payouts',
  kAdminZones: 'Zones & Pincodes',
  kAdminNotifications: 'Notifications',
  kAdminReviews: 'Reviews',
  kAdminConfig: 'Platform Config',
  kAdminCoupons: 'Coupons',
  kAdminWallets: 'Wallets',
  kAdminReferrals: 'Referrals',
  kAdminLoyalty: 'Loyalty Program',
  kAdminEnhancedAnalytics: 'Enhanced Analytics',
};

// ── Unread notification count (stub -- wire to Supabase later) ────
class UnreadCountNotifier extends Notifier<int> {
  @override
  int build() => 3;

  void set(int count) => state = count;
}

final unreadNotificationCountProvider =
    NotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);
