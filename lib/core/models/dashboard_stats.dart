class DashboardStats {
  final int ordersToday;
  final double groceryRevenueToday;
  final int activeVendors;
  final int pendingVendors;
  final int deliveryAgentsOnline;
  final int bookingsToday;
  final double serviceRevenueToday;
  final int activeWorkers;
  final int pendingBgvWorkers;
  final int alertCount;
  final double totalGmvToday;
  final double platformCommissionToday;
  final List<DailyCount> ordersLast7Days;
  final List<DailyCount> bookingsLast7Days;
  final List<Map<String, dynamic>> activityFeed;
  final int failedPayments;
  final int pendingVendorApprovals;
  final int unassignedBookings;
  final int lowStockProducts;

  DashboardStats({
    this.ordersToday = 0,
    this.groceryRevenueToday = 0,
    this.activeVendors = 0,
    this.pendingVendors = 0,
    this.deliveryAgentsOnline = 0,
    this.bookingsToday = 0,
    this.serviceRevenueToday = 0,
    this.activeWorkers = 0,
    this.pendingBgvWorkers = 0,
    this.alertCount = 0,
    this.totalGmvToday = 0,
    this.platformCommissionToday = 0,
    this.ordersLast7Days = const [],
    this.bookingsLast7Days = const [],
    this.activityFeed = const [],
    this.failedPayments = 0,
    this.pendingVendorApprovals = 0,
    this.unassignedBookings = 0,
    this.lowStockProducts = 0,
  });
}

class DailyCount {
  final DateTime date;
  final int count;
  final double revenue;

  DailyCount({
    required this.date,
    this.count = 0,
    this.revenue = 0,
  });
}
