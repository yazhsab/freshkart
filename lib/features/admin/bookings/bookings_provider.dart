import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/service_category.dart';
import '../../../core/supabase/client.dart';

// ── State ────────────────────────────────────────────────────────

class BookingListState {
  const BookingListState({
    this.bookings = const [],
    this.statusFilter = 'All',
    this.dateRange,
    this.categoryFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.unassignedCount = 0,
    this.serviceCategories = const [],
  });

  final List<Booking> bookings;
  final String statusFilter;
  final ProviderDateTimeRange? dateRange;
  final String? categoryFilter; // service_category id
  final String searchQuery;
  final bool isLoading;
  final int unassignedCount;
  final List<ServiceCategory> serviceCategories;

  BookingListState copyWith({
    List<Booking>? bookings,
    String? statusFilter,
    ProviderDateTimeRange? Function()? dateRange,
    String? Function()? categoryFilter,
    String? searchQuery,
    bool? isLoading,
    int? unassignedCount,
    List<ServiceCategory>? serviceCategories,
  }) {
    return BookingListState(
      bookings: bookings ?? this.bookings,
      statusFilter: statusFilter ?? this.statusFilter,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      categoryFilter:
          categoryFilter != null ? categoryFilter() : this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      unassignedCount: unassignedCount ?? this.unassignedCount,
      serviceCategories: serviceCategories ?? this.serviceCategories,
    );
  }

  /// Filtered bookings (local filters after DB fetch).
  List<Booking> get filtered {
    var list = bookings;

    // Status
    if (statusFilter != 'All') {
      list = list.where((b) => b.status == statusFilter).toList();
    }

    // Date range
    if (dateRange != null) {
      list = list.where((b) {
        return !b.slotDate.isBefore(dateRange!.start) &&
            !b.slotDate
                .isAfter(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Category
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      list = list
          .where((b) => b.serviceCategoryId == categoryFilter)
          .toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((b) {
        final bNum = b.bookingNumber?.toLowerCase() ?? '';
        final custName = b.customer?.displayName.toLowerCase() ?? '';
        final custPhone = b.customer?.phone.toLowerCase() ?? '';
        final workerName = b.worker?.displayName.toLowerCase() ?? '';
        return bNum.contains(q) ||
            custName.contains(q) ||
            custPhone.contains(q) ||
            workerName.contains(q);
      }).toList();
    }

    return list;
  }
}

/// Simple date range class so the provider file doesn't need to import
/// Flutter's material library.  Screens should convert from Flutter's
/// `DateTimeRange` before passing values here.
class ProviderDateTimeRange {
  const ProviderDateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

// ── Notifier ─────────────────────────────────────────────────────

class BookingListNotifier extends Notifier<BookingListState> {
  @override
  BookingListState build() {
    Future.microtask(() => loadBookings());
    return const BookingListState(isLoading: true);
  }

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true);
    try {
      final rows = await adminClient
          .from('bookings')
          .select(
            '*, '
            'customer:profiles!bookings_customer_id_fkey(id, full_name, phone, email, avatar_url, role), '
            'workers!bookings_worker_id_fkey(id, profile_id, bio, aadhaar_number, aadhaar_doc_url, '
            'police_verification_url, skill_certificate_urls, service_category_ids, '
            'experience_years, city, service_pincodes, is_available, is_approved, '
            'bgv_status, bgv_notes, rating, total_ratings, total_jobs_completed, created_at, '
            'profiles!workers_profile_id_fkey(id, full_name, phone, email, avatar_url)), '
            'service_categories(id, name, name_tamil, icon_url, description, base_price, '
            'price_type, estimated_duration_mins, is_active, sort_order)',
          )
          .order('created_at', ascending: false)
          .limit(500);

      final bookings =
          rows.map<Booking>((r) => Booking.fromJson(r)).toList();

      final unassigned = bookings.where((b) => b.isUnassigned && b.status != 'cancelled').length;

      // Fetch categories for filter dropdown.
      final catRows = await adminClient
          .from('service_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      final categories = catRows
          .map<ServiceCategory>((r) => ServiceCategory.fromJson(r))
          .toList();

      state = state.copyWith(
        bookings: bookings,
        isLoading: false,
        unassignedCount: unassigned,
        serviceCategories: categories,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setDateRange(ProviderDateTimeRange? range) {
    state = state.copyWith(dateRange: () => range);
  }

  void setCategoryFilter(String? catId) {
    state = state.copyWith(categoryFilter: () => catId);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> assignWorker(String bookingId, String workerId) async {
    await adminClient.from('bookings').update({
      'worker_id': workerId,
      'status': 'assigned',
    }).eq('id', bookingId);

    // Notify worker.
    final worker = await adminClient
        .from('workers')
        .select('profile_id')
        .eq('id', workerId)
        .single();
    final booking = await adminClient
        .from('bookings')
        .select('booking_number')
        .eq('id', bookingId)
        .single();

    await adminClient.from('notifications_log').insert({
      'user_id': worker['profile_id'],
      'ref_type': 'booking',
      'ref_id': bookingId,
      'title': 'New Booking Assigned',
      'body':
          'You have been assigned booking #${booking['booking_number']}.',
      'type': 'booking',
    });

    await loadBookings();
  }

  Future<void> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newStart,
    String newEnd,
  ) async {
    await adminClient.from('bookings').update({
      'slot_date': newDate.toIso8601String().split('T')[0],
      'slot_start': newStart,
      'slot_end': newEnd,
    }).eq('id', bookingId);

    // Notify customer.
    final booking = await adminClient
        .from('bookings')
        .select('customer_id, booking_number')
        .eq('id', bookingId)
        .single();
    await adminClient.from('notifications_log').insert({
      'user_id': booking['customer_id'],
      'ref_type': 'booking',
      'ref_id': bookingId,
      'title': 'Booking Rescheduled',
      'body':
          'Your booking #${booking['booking_number']} has been rescheduled.',
      'type': 'booking',
    });

    await loadBookings();
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    await adminClient.from('bookings').update({
      'status': 'cancelled',
      'cancelled_by': 'admin',
      'cancel_reason': reason,
    }).eq('id', bookingId);

    final booking = await adminClient
        .from('bookings')
        .select('customer_id, booking_number')
        .eq('id', bookingId)
        .single();
    await adminClient.from('notifications_log').insert({
      'user_id': booking['customer_id'],
      'ref_type': 'booking',
      'ref_id': bookingId,
      'title': 'Booking Cancelled',
      'body':
          'Your booking #${booking['booking_number']} has been cancelled. Reason: $reason',
      'type': 'alert',
    });

    await loadBookings();
  }

  Future<void> markDisputed(String bookingId, String reason) async {
    await adminClient.from('bookings').update({
      'status': 'disputed',
      'dispute_reason': reason,
    }).eq('id', bookingId);

    await loadBookings();
  }

  Future<void> resolveDispute(
    String bookingId,
    String resolution,
    double? overridePrice,
  ) async {
    final updates = <String, dynamic>{
      'status': 'completed',
      'dispute_reason': null,
      'worker_notes': 'Dispute resolved: $resolution',
    };
    if (overridePrice != null) {
      updates['final_price'] = overridePrice;
    }

    await adminClient.from('bookings').update(updates).eq('id', bookingId);

    final booking = await adminClient
        .from('bookings')
        .select('customer_id, booking_number')
        .eq('id', bookingId)
        .single();
    await adminClient.from('notifications_log').insert({
      'user_id': booking['customer_id'],
      'ref_type': 'booking',
      'ref_id': bookingId,
      'title': 'Dispute Resolved',
      'body':
          'The dispute on booking #${booking['booking_number']} has been resolved.',
      'type': 'booking',
    });

    await loadBookings();
  }

  Future<void> overridePrice(String bookingId, double newPrice) async {
    await adminClient.from('bookings').update({
      'final_price': newPrice,
    }).eq('id', bookingId);

    await loadBookings();
  }
}

final bookingListProvider =
    NotifierProvider<BookingListNotifier, BookingListState>(
  BookingListNotifier.new,
);

// ── Selected booking for detail panel ────────────────────────────

class SelectedBookingIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedBookingIdProvider =
    NotifierProvider<SelectedBookingIdNotifier, String?>(
  SelectedBookingIdNotifier.new,
);

// ── Available workers for assignment ─────────────────────────────

final availableWorkersForBookingProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, serviceCategoryId) async {
    final rows = await adminClient
        .from('workers')
        .select(
          'id, city, rating, total_jobs_completed, is_available, service_category_ids, '
          'profiles!workers_profile_id_fkey(full_name, phone, avatar_url)',
        )
        .eq('is_approved', true)
        .eq('bgv_status', 'approved')
        .eq('is_available', true)
        .order('rating', ascending: false);

    // Filter to workers that have the required service category.
    final filtered = rows.where((r) {
      final catIds = (r['service_category_ids'] as List<dynamic>?) ?? [];
      return catIds.contains(serviceCategoryId);
    }).toList();

    return filtered;
  },
);
