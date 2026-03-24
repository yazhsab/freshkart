import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/client.dart';
import '../../../core/utils/date_helpers.dart';

// ── Period enum ─────────────────────────────────────────────────

enum WorkerPayoutPeriod { thisWeek, lastWeek, thisMonth, custom }

// ── Period filter provider ──────────────────────────────────────

final workerPayoutPeriodProvider =
    NotifierProvider<WorkerPayoutPeriodNotifier, WorkerPayoutPeriod>(
  WorkerPayoutPeriodNotifier.new,
);

class WorkerPayoutPeriodNotifier extends Notifier<WorkerPayoutPeriod> {
  @override
  WorkerPayoutPeriod build() => WorkerPayoutPeriod.thisWeek;
  void set(WorkerPayoutPeriod p) => state = p;
}

// ── Custom date range ───────────────────────────────────────────

final workerPayoutCustomRangeProvider =
    NotifierProvider<WorkerPayoutCustomRangeNotifier, WorkerDateTimeRange?>(
  WorkerPayoutCustomRangeNotifier.new,
);

class WorkerDateTimeRange {
  final DateTime start;
  final DateTime end;
  const WorkerDateTimeRange({required this.start, required this.end});
}

class WorkerPayoutCustomRangeNotifier extends Notifier<WorkerDateTimeRange?> {
  @override
  WorkerDateTimeRange? build() => null;
  void set(WorkerDateTimeRange? range) => state = range;
}

// ── Worker payout row model ─────────────────────────────────────

class WorkerPayoutRow {
  final String workerId;
  final String workerName;
  final int bookingCount;
  final double grossAmount;
  final double commissionAmount; // 20% platform commission
  final double netAmount;
  final double adjustments;
  final String? lastPaidDate;
  final String status; // pending, paid, partial, on_hold
  final int disputeCount;

  const WorkerPayoutRow({
    required this.workerId,
    required this.workerName,
    required this.bookingCount,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    this.adjustments = 0,
    this.lastPaidDate,
    required this.status,
    this.disputeCount = 0,
  });
}

// ── Worker payouts summary model ────────────────────────────────

class WorkerPayoutsSummary {
  final double totalGmv;
  final double totalCommission;
  final double totalToPay;
  final double totalPaid;
  final double totalPending;
  final int totalDisputes;
  final List<WorkerPayoutRow> rows;

  const WorkerPayoutsSummary({
    required this.totalGmv,
    required this.totalCommission,
    required this.totalToPay,
    required this.totalPaid,
    required this.totalPending,
    required this.totalDisputes,
    required this.rows,
  });
}

// ── Helper: compute period dates ────────────────────────────────

({DateTime start, DateTime end}) _periodDates(
    WorkerPayoutPeriod period, WorkerDateTimeRange? customRange) {
  final now = DateTime.now();
  switch (period) {
    case WorkerPayoutPeriod.thisWeek:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return (start: start, end: now);
    case WorkerPayoutPeriod.lastWeek:
      final thisWeekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final start = thisWeekStart.subtract(const Duration(days: 7));
      return (start: start, end: thisWeekStart);
    case WorkerPayoutPeriod.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      return (start: start, end: now);
    case WorkerPayoutPeriod.custom:
      if (customRange != null) {
        return (start: customRange.start, end: customRange.end);
      }
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return (start: start, end: now);
  }
}

// ── Worker payouts provider ─────────────────────────────────────

final workerPayoutsProvider =
    FutureProvider<WorkerPayoutsSummary>((ref) async {
  final period = ref.watch(workerPayoutPeriodProvider);
  final customRange = ref.watch(workerPayoutCustomRangeProvider);
  final dates = _periodDates(period, customRange);
  final db = adminClient;

  final startStr = dates.start.toIso8601String();
  final endStr = dates.end.toIso8601String();

  // Fetch all approved workers with profiles
  final workers = await db
      .from('workers')
      .select('id, profile_id, profiles(full_name, phone)')
      .eq('is_approved', true)
      .order('created_at', ascending: false);

  // Fetch completed bookings in period
  final bookings = await db
      .from('bookings')
      .select('worker_id, final_price, quoted_price, status, dispute_reason')
      .inFilter('status', ['completed', 'disputed'])
      .gte('created_at', startStr)
      .lte('created_at', endStr);

  // Fetch payouts in period
  final payouts = await db
      .from('payouts')
      .select()
      .eq('payee_type', 'worker')
      .gte('created_at', startStr)
      .lte('created_at', endStr);

  // Group bookings by worker
  final workerBookings = <String, List<Map<String, dynamic>>>{};
  for (final b in bookings) {
    final wid = b['worker_id'] as String?;
    if (wid != null) {
      workerBookings
          .putIfAbsent(wid, () => [])
          .add(b as Map<String, dynamic>);
    }
  }

  // Group payouts by worker
  final workerPayoutsMap = <String, List<Map<String, dynamic>>>{};
  for (final p in payouts) {
    final wid = p['payee_id'] as String?;
    if (wid != null) {
      workerPayoutsMap
          .putIfAbsent(wid, () => [])
          .add(p as Map<String, dynamic>);
    }
  }

  const commissionRate = 0.20; // 20% platform commission
  var totalGmv = 0.0;
  var totalCommission = 0.0;
  var totalPaid = 0.0;
  var totalPending = 0.0;
  var totalDisputes = 0;

  final rows = <WorkerPayoutRow>[];

  for (final w in workers) {
    final wid = w['id'] as String;
    final profile = w['profiles'] as Map<String, dynamic>?;
    final workerName = profile?['full_name'] as String? ??
        profile?['phone'] as String? ??
        'Worker';
    final wBookings = workerBookings[wid] ?? [];
    final wPayouts = workerPayoutsMap[wid] ?? [];

    if (wBookings.isEmpty && wPayouts.isEmpty) continue;

    var gross = 0.0;
    var disputes = 0;
    for (final b in wBookings) {
      final price = ((b['final_price'] as num?) ??
              (b['quoted_price'] as num?) ??
              0)
          .toDouble();
      gross += price;
      if (b['status'] == 'disputed') disputes++;
    }

    final commission = gross * commissionRate;
    final net = gross - commission;

    var paid = 0.0;
    var adjustments = 0.0;
    String? lastPaidDate;
    for (final p in wPayouts) {
      if (p['status'] == 'paid') {
        paid += ((p['net_amount'] as num?) ?? 0).toDouble();
        final paidAt = p['paid_at']?.toString();
        if (paidAt != null) {
          final dt = DateTime.tryParse(paidAt);
          if (dt != null) lastPaidDate = formatDate(dt);
        }
      }
      // Track adjustments from notes
      if (p['notes']?.toString().contains('adjustment') == true) {
        adjustments +=
            ((p['net_amount'] as num?) ?? 0).toDouble();
      }
    }

    final pending = net - paid;
    String status;
    if (disputes > 0 && paid == 0) {
      status = 'on_hold';
    } else if (paid >= net) {
      status = 'paid';
    } else if (paid > 0) {
      status = 'partial';
    } else {
      status = 'pending';
    }

    totalGmv += gross;
    totalCommission += commission;
    totalPaid += paid;
    totalPending += pending > 0 ? pending : 0;
    totalDisputes += disputes;

    rows.add(WorkerPayoutRow(
      workerId: wid,
      workerName: workerName,
      bookingCount: wBookings.length,
      grossAmount: gross,
      commissionAmount: commission,
      netAmount: net,
      adjustments: adjustments,
      lastPaidDate: lastPaidDate,
      status: status,
      disputeCount: disputes,
    ));
  }

  // Sort by net descending
  rows.sort((a, b) => b.netAmount.compareTo(a.netAmount));

  return WorkerPayoutsSummary(
    totalGmv: totalGmv,
    totalCommission: totalCommission,
    totalToPay: totalGmv - totalCommission,
    totalPaid: totalPaid,
    totalPending: totalPending,
    totalDisputes: totalDisputes,
    rows: rows,
  );
});

// ── Worker payout actions ───────────────────────────────────────

final workerPayoutActionsProvider =
    NotifierProvider<WorkerPayoutActionsNotifier, void>(
  WorkerPayoutActionsNotifier.new,
);

class WorkerPayoutActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markPaid({
    required String workerId,
    required double grossAmount,
    required double commissionAmount,
    required double netAmount,
    String? paymentReference,
  }) async {
    final period = ref.read(workerPayoutPeriodProvider);
    final customRange = ref.read(workerPayoutCustomRangeProvider);
    final dates = _periodDates(period, customRange);

    await adminClient.from('payouts').insert({
      'payee_type': 'worker',
      'payee_id': workerId,
      'period_start': dates.start.toIso8601String().split('T')[0],
      'period_end': dates.end.toIso8601String().split('T')[0],
      'gross_amount': grossAmount,
      'commission_amount': commissionAmount,
      'net_amount': netAmount,
      'status': 'paid',
      'payment_reference': paymentReference,
      'paid_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(workerPayoutsProvider);
  }

  Future<void> holdPayment({
    required String workerId,
    required double netAmount,
    required String reason,
  }) async {
    final period = ref.read(workerPayoutPeriodProvider);
    final customRange = ref.read(workerPayoutCustomRangeProvider);
    final dates = _periodDates(period, customRange);

    await adminClient.from('payouts').insert({
      'payee_type': 'worker',
      'payee_id': workerId,
      'period_start': dates.start.toIso8601String().split('T')[0],
      'period_end': dates.end.toIso8601String().split('T')[0],
      'gross_amount': 0,
      'commission_amount': 0,
      'net_amount': 0,
      'status': 'on_hold',
      'notes': 'Payment held: $reason',
    });

    ref.invalidate(workerPayoutsProvider);
  }

  Future<void> addAdjustment({
    required String workerId,
    required double amount,
    required String reason,
  }) async {
    final period = ref.read(workerPayoutPeriodProvider);
    final customRange = ref.read(workerPayoutCustomRangeProvider);
    final dates = _periodDates(period, customRange);

    await adminClient.from('payouts').insert({
      'payee_type': 'worker',
      'payee_id': workerId,
      'period_start': dates.start.toIso8601String().split('T')[0],
      'period_end': dates.end.toIso8601String().split('T')[0],
      'gross_amount': 0,
      'commission_amount': 0,
      'net_amount': amount,
      'status': 'paid',
      'notes': 'adjustment: $reason',
      'paid_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(workerPayoutsProvider);
  }
}
