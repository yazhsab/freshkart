import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── Filter & search state ────────────────────────────────────────

final customerFilterProvider =
    NotifierProvider<CustomerFilterNotifier, String>(
  CustomerFilterNotifier.new,
);

class CustomerFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String f) => state = f;
}

final customerSearchProvider =
    NotifierProvider<CustomerSearchNotifier, String>(
  CustomerSearchNotifier.new,
);

class CustomerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final customerSortProvider =
    NotifierProvider<CustomerSortNotifier, String>(
  CustomerSortNotifier.new,
);

class CustomerSortNotifier extends Notifier<String> {
  @override
  String build() => 'joined_desc';
  void set(String s) => state = s;
}

// ── Customer model ───────────────────────────────────────────────

class CustomerRow {
  final String id;
  final String? fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;
  final int orderCount;
  final double orderSpend;
  final int bookingCount;
  final double bookingSpend;
  final DateTime? lastActive;

  CustomerRow({
    required this.id,
    this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.isActive,
    this.createdAt,
    required this.orderCount,
    required this.orderSpend,
    required this.bookingCount,
    required this.bookingSpend,
    this.lastActive,
  });

  double get totalSpend => orderSpend + bookingSpend;

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : phone;

  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get statusLabel {
    if (!isActive) return 'Banned';
    if (createdAt != null &&
        DateTime.now().difference(createdAt!).inDays <= 7) {
      return 'New';
    }
    return 'Active';
  }
}

// ── Customers provider ───────────────────────────────────────────

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<CustomerRow>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<CustomerRow>> {
  @override
  Future<List<CustomerRow>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<CustomerRow>> _fetch() async {
    final filter = ref.watch(customerFilterProvider);
    final search = ref.watch(customerSearchProvider).trim().toLowerCase();
    final sort = ref.watch(customerSortProvider);

    // Fetch all customers
    var query = adminClient
        .from('profiles')
        .select()
        .eq('role', 'customer');

    if (filter == 'Banned') {
      query = query.eq('is_active', false);
    } else if (filter == 'Active' || filter == 'New') {
      query = query.eq('is_active', true);
    }

    final rows = await query.order('created_at', ascending: false);

    final now = DateTime.now();
    final customers = <CustomerRow>[];

    for (final row in rows) {
      final id = row['id'] as String;
      final name = row['full_name'] as String? ?? '';
      final phone = row['phone'] as String? ?? '';
      final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');

      // Client-side search
      if (search.isNotEmpty) {
        if (!name.toLowerCase().contains(search) &&
            !phone.contains(search)) {
          continue;
        }
      }

      // Filter "New" (joined in last 7 days)
      if (filter == 'New') {
        if (createdAt == null ||
            now.difference(createdAt).inDays > 7) {
          continue;
        }
      }

      // Fetch order stats
      final orderRows = await adminClient
          .from('orders')
          .select('final_amount, created_at')
          .eq('customer_id', id)
          .inFilter('status',
              ['confirmed', 'packing', 'ready', 'picked_up', 'delivered']);

      int orderCount = orderRows.length;
      double orderSpend = 0;
      DateTime? lastOrderAt;
      for (final o in orderRows) {
        orderSpend += ((o['final_amount'] as num?) ?? 0).toDouble();
        final oDate = DateTime.tryParse(o['created_at']?.toString() ?? '');
        if (oDate != null && (lastOrderAt == null || oDate.isAfter(lastOrderAt))) {
          lastOrderAt = oDate;
        }
      }

      // Fetch booking stats
      final bookingRows = await adminClient
          .from('bookings')
          .select('final_price, booking_fee, created_at')
          .eq('customer_id', id)
          .inFilter('status', ['assigned', 'confirmed', 'worker_on_way', 'in_progress', 'completed']);

      int bookingCount = bookingRows.length;
      double bookingSpend = 0;
      DateTime? lastBookingAt;
      for (final b in bookingRows) {
        bookingSpend += ((b['final_price'] as num?) ?? 0).toDouble();
        bookingSpend += ((b['booking_fee'] as num?) ?? 0).toDouble();
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
        if (bDate != null && (lastBookingAt == null || bDate.isAfter(lastBookingAt))) {
          lastBookingAt = bDate;
        }
      }

      // Determine last active
      DateTime? lastActive;
      if (lastOrderAt != null && lastBookingAt != null) {
        lastActive = lastOrderAt.isAfter(lastBookingAt) ? lastOrderAt : lastBookingAt;
      } else {
        lastActive = lastOrderAt ?? lastBookingAt;
      }

      customers.add(CustomerRow(
        id: id,
        fullName: name,
        phone: phone,
        email: row['email'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        isActive: row['is_active'] as bool? ?? true,
        createdAt: createdAt,
        orderCount: orderCount,
        orderSpend: orderSpend,
        bookingCount: bookingCount,
        bookingSpend: bookingSpend,
        lastActive: lastActive,
      ));
    }

    // Sorting
    switch (sort) {
      case 'joined_desc':
        customers.sort((a, b) =>
            (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      case 'joined_asc':
        customers.sort((a, b) =>
            (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000)));
      case 'spend_desc':
        customers.sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
      case 'spend_asc':
        customers.sort((a, b) => a.totalSpend.compareTo(b.totalSpend));
      case 'name_asc':
        customers.sort(
            (a, b) => a.displayName.compareTo(b.displayName));
      case 'orders_desc':
        customers.sort((a, b) =>
            (b.orderCount + b.bookingCount)
                .compareTo(a.orderCount + a.bookingCount));
    }

    return customers;
  }

  Future<void> toggleBan(String customerId, bool ban) async {
    await adminClient
        .from('profiles')
        .update({'is_active': !ban}).eq('id', customerId);
    await refresh();
  }
}

// ── Selected customer ────────────────────────────────────────────

final selectedCustomerIdProvider =
    NotifierProvider<SelectedCustomerIdNotifier, String?>(
  SelectedCustomerIdNotifier.new,
);

class SelectedCustomerIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

// ── Customer orders ──────────────────────────────────────────────

final customerOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  return await adminClient
      .from('orders')
      .select('id, order_number, final_amount, status, created_at, vendors(shop_name)')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(50);
});

// ── Customer bookings ────────────────────────────────────────────

final customerBookingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  return await adminClient
      .from('bookings')
      .select(
          'id, booking_number, final_price, booking_fee, status, slot_date, slot_start, created_at, service_categories(name)')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(50);
});

// ── Customer payments ────────────────────────────────────────────

final customerPaymentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final orders = await adminClient
      .from('orders')
      .select('id, order_number, final_amount, payment_method, payment_status, created_at')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(30);

  final bookings = await adminClient
      .from('bookings')
      .select(
          'id, booking_number, final_price, booking_fee, payment_method, payment_status, created_at')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(30);

  // Combine and sort by date
  final all = <Map<String, dynamic>>[];
  for (final o in orders) {
    all.add({
      'type': 'order',
      'ref': o['order_number'] ?? o['id'],
      'amount': o['final_amount'],
      'method': o['payment_method'],
      'status': o['payment_status'],
      'date': o['created_at'],
    });
  }
  for (final b in bookings) {
    final price = ((b['final_price'] as num?) ?? 0).toDouble();
    final fee = ((b['booking_fee'] as num?) ?? 0).toDouble();
    all.add({
      'type': 'booking',
      'ref': b['booking_number'] ?? b['id'],
      'amount': price + fee,
      'method': b['payment_method'],
      'status': b['payment_status'],
      'date': b['created_at'],
    });
  }
  all.sort((a, b) =>
      (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''));
  return all;
});
