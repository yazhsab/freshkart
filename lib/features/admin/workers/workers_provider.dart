import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/worker.dart';
import '../../../core/models/service_category.dart';
import '../../../core/supabase/client.dart';

// ── State ────────────────────────────────────────────────────────

class WorkerListState {
  const WorkerListState({
    this.workers = const [],
    this.bgvFilter = 'All',
    this.skillFilter,
    this.cityFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.serviceCategories = const [],
  });

  final List<Worker> workers;
  final String bgvFilter; // All, pending, in_progress, approved, rejected
  final String? skillFilter; // service_category id
  final String? cityFilter;
  final String searchQuery;
  final bool isLoading;
  final List<ServiceCategory> serviceCategories;

  WorkerListState copyWith({
    List<Worker>? workers,
    String? bgvFilter,
    String? Function()? skillFilter,
    String? Function()? cityFilter,
    String? searchQuery,
    bool? isLoading,
    List<ServiceCategory>? serviceCategories,
  }) {
    return WorkerListState(
      workers: workers ?? this.workers,
      bgvFilter: bgvFilter ?? this.bgvFilter,
      skillFilter: skillFilter != null ? skillFilter() : this.skillFilter,
      cityFilter: cityFilter != null ? cityFilter() : this.cityFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      serviceCategories: serviceCategories ?? this.serviceCategories,
    );
  }

  /// Workers after local filtering.
  List<Worker> get filtered {
    var list = workers;

    // BGV filter
    if (bgvFilter != 'All') {
      list = list.where((w) => w.bgvStatus == bgvFilter).toList();
    }

    // Skill (service category) filter
    if (skillFilter != null && skillFilter!.isNotEmpty) {
      list = list
          .where((w) => w.serviceCategoryIds.contains(skillFilter))
          .toList();
    }

    // City filter
    if (cityFilter != null && cityFilter!.isNotEmpty) {
      list = list.where((w) => w.city == cityFilter).toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((w) {
        final name = w.displayName.toLowerCase();
        final phone = w.profile?.phone.toLowerCase() ?? '';
        final aadhaar = w.aadhaarNumber?.toLowerCase() ?? '';
        return name.contains(q) || phone.contains(q) || aadhaar.contains(q);
      }).toList();
    }

    return list;
  }

  /// Distinct cities from all workers.
  List<String> get cities {
    final set = <String>{};
    for (final w in workers) {
      if (w.city.isNotEmpty) set.add(w.city);
    }
    final sorted = set.toList()..sort();
    return sorted;
  }
}

// ── Notifier ─────────────────────────────────────────────────────

class WorkerListNotifier extends Notifier<WorkerListState> {
  @override
  WorkerListState build() {
    // Auto-load on build.
    Future.microtask(() => loadWorkers());
    return const WorkerListState(isLoading: true);
  }

  Future<void> loadWorkers() async {
    state = state.copyWith(isLoading: true);
    try {
      final rows = await adminClient
          .from('workers')
          .select(
            'id, profile_id, bio, aadhaar_number, aadhaar_doc_url, '
            'police_verification_url, skill_certificate_urls, '
            'service_category_ids, experience_years, city, service_pincodes, '
            'is_available, is_approved, bgv_status, bgv_notes, rating, '
            'total_ratings, total_jobs_completed, created_at, '
            'profiles!workers_profile_id_fkey(id, full_name, phone, email, avatar_url)',
          )
          .order('created_at', ascending: false);

      final workers = rows.map<Worker>((r) => Worker.fromJson(r)).toList();

      // Fetch service categories for filter dropdowns.
      final catRows = await adminClient
          .from('service_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      final categories =
          catRows.map<ServiceCategory>((r) => ServiceCategory.fromJson(r)).toList();

      state = state.copyWith(
        workers: workers,
        isLoading: false,
        serviceCategories: categories,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setBgvFilter(String filter) {
    state = state.copyWith(bgvFilter: filter);
  }

  void setSkillFilter(String? skillId) {
    state = state.copyWith(skillFilter: () => skillId);
  }

  void setCityFilter(String? city) {
    state = state.copyWith(cityFilter: () => city);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> updateBgvStatus(
    String workerId,
    String status,
    String? notes,
  ) async {
    final updates = <String, dynamic>{
      'bgv_status': status,
      'bgv_notes': notes,
    };
    if (status == 'approved') {
      updates['is_approved'] = true;
    } else if (status == 'rejected') {
      updates['is_approved'] = false;
    }

    await adminClient.from('workers').update(updates).eq('id', workerId);

    // Notify the worker.
    final worker = await adminClient
        .from('workers')
        .select('profile_id')
        .eq('id', workerId)
        .single();
    final title = status == 'approved'
        ? 'BGV Approved!'
        : status == 'rejected'
            ? 'BGV Rejected'
            : 'BGV Update';
    final body = status == 'approved'
        ? 'Your background verification is approved. You can now accept bookings.'
        : status == 'rejected'
            ? 'Your background verification was rejected. Reason: ${notes ?? 'N/A'}'
            : 'Your BGV status has been updated to $status.';

    await adminClient.from('notifications_log').insert({
      'user_id': worker['profile_id'],
      'ref_type': 'worker',
      'ref_id': workerId,
      'title': title,
      'body': body,
      'type': 'worker',
    });

    await loadWorkers();
  }

  Future<void> suspendWorker(String workerId) async {
    await adminClient.from('workers').update({
      'is_approved': false,
      'is_available': false,
    }).eq('id', workerId);

    final worker = await adminClient
        .from('workers')
        .select('profile_id')
        .eq('id', workerId)
        .single();
    await adminClient.from('notifications_log').insert({
      'user_id': worker['profile_id'],
      'ref_type': 'worker',
      'ref_id': workerId,
      'title': 'Account Suspended',
      'body':
          'Your worker account has been suspended. Please contact support for details.',
      'type': 'alert',
    });

    await loadWorkers();
  }

  Future<void> reinstateWorker(String workerId) async {
    await adminClient.from('workers').update({
      'is_approved': true,
      'is_available': true,
    }).eq('id', workerId);

    final worker = await adminClient
        .from('workers')
        .select('profile_id')
        .eq('id', workerId)
        .single();
    await adminClient.from('notifications_log').insert({
      'user_id': worker['profile_id'],
      'ref_type': 'worker',
      'ref_id': workerId,
      'title': 'Account Reinstated',
      'body':
          'Your worker account has been reinstated. You can now accept bookings again.',
      'type': 'worker',
    });

    await loadWorkers();
  }
}

final workerListProvider =
    NotifierProvider<WorkerListNotifier, WorkerListState>(
  WorkerListNotifier.new,
);

// ── Selected worker for detail panel ─────────────────────────────

class SelectedWorkerIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedWorkerIdProvider =
    NotifierProvider<SelectedWorkerIdNotifier, String?>(
  SelectedWorkerIdNotifier.new,
);

// ── Worker booking history (family) ──────────────────────────────

final workerBookingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, workerId) async {
    return await adminClient
        .from('bookings')
        .select(
          'id, booking_number, status, slot_date, slot_start, slot_end, '
          'quoted_price, final_price, payment_status, created_at, '
          'customer:profiles!bookings_customer_id_fkey(full_name, phone), '
          'service_categories(name)',
        )
        .eq('worker_id', workerId)
        .order('slot_date', ascending: false)
        .limit(100);
  },
);

// ── Worker payouts (family) ──────────────────────────────────────

final workerPayoutsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, workerId) async {
    final payouts = await adminClient
        .from('payouts')
        .select()
        .eq('payee_type', 'worker')
        .eq('payee_id', workerId)
        .order('created_at', ascending: false);

    var totalEarned = 0.0;
    var totalCommission = 0.0;
    var totalPaid = 0.0;
    var pending = 0.0;

    for (final p in payouts) {
      totalEarned += ((p['gross_amount'] as num?) ?? 0).toDouble();
      totalCommission += ((p['commission_amount'] as num?) ?? 0).toDouble();
      if (p['status'] == 'paid') {
        totalPaid += ((p['net_amount'] as num?) ?? 0).toDouble();
      } else if (p['status'] == 'pending') {
        pending += ((p['net_amount'] as num?) ?? 0).toDouble();
      }
    }

    return {
      'totalEarned': totalEarned,
      'totalCommission': totalCommission,
      'totalPaid': totalPaid,
      'pending': pending,
      'records': payouts,
    };
  },
);
