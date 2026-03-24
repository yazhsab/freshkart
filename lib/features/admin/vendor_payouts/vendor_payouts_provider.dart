import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/client.dart';
import '../../../core/utils/date_helpers.dart';

// ── Period enum ─────────────────────────────────────────────────

enum PayoutPeriod { thisWeek, lastWeek, thisMonth, custom }

// ── Period filter provider ──────────────────────────────────────

final vendorPayoutPeriodProvider =
    NotifierProvider<VendorPayoutPeriodNotifier, PayoutPeriod>(
  VendorPayoutPeriodNotifier.new,
);

class VendorPayoutPeriodNotifier extends Notifier<PayoutPeriod> {
  @override
  PayoutPeriod build() => PayoutPeriod.thisWeek;
  void set(PayoutPeriod p) => state = p;
}

// ── Custom date range ───────────────────────────────────────────

final vendorPayoutCustomRangeProvider =
    NotifierProvider<VendorPayoutCustomRangeNotifier, PayoutDateRange?>(
  VendorPayoutCustomRangeNotifier.new,
);

class PayoutDateRange {
  final DateTime start;
  final DateTime end;
  const PayoutDateRange({required this.start, required this.end});
}

class VendorPayoutCustomRangeNotifier extends Notifier<PayoutDateRange?> {
  @override
  PayoutDateRange? build() => null;
  void set(PayoutDateRange? range) => state = range;
}

// ── Vendor payout row model ─────────────────────────────────────

class VendorPayoutRow {
  final String vendorId;
  final String shopName;
  final int orderCount;
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final String? lastPaidDate;
  final String status; // pending, paid, partial

  const VendorPayoutRow({
    required this.vendorId,
    required this.shopName,
    required this.orderCount,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    this.lastPaidDate,
    required this.status,
  });
}

// ── Vendor payouts summary model ────────────────────────────────

class VendorPayoutsSummary {
  final double totalGmv;
  final double totalCommission;
  final double totalToPay;
  final double totalPaid;
  final double totalPending;
  final List<VendorPayoutRow> rows;

  const VendorPayoutsSummary({
    required this.totalGmv,
    required this.totalCommission,
    required this.totalToPay,
    required this.totalPaid,
    required this.totalPending,
    required this.rows,
  });
}

// ── Helper: compute period dates ────────────────────────────────

({DateTime start, DateTime end}) _periodDates(
    PayoutPeriod period, PayoutDateRange? customRange) {
  final now = DateTime.now();
  switch (period) {
    case PayoutPeriod.thisWeek:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return (start: start, end: now);
    case PayoutPeriod.lastWeek:
      final thisWeekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final start = thisWeekStart.subtract(const Duration(days: 7));
      return (start: start, end: thisWeekStart);
    case PayoutPeriod.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      return (start: start, end: now);
    case PayoutPeriod.custom:
      if (customRange != null) {
        return (start: customRange.start, end: customRange.end);
      }
      // Fallback to this week
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return (start: start, end: now);
  }
}

// ── Vendor payouts provider ─────────────────────────────────────

final vendorPayoutsProvider =
    FutureProvider<VendorPayoutsSummary>((ref) async {
  final period = ref.watch(vendorPayoutPeriodProvider);
  final customRange = ref.watch(vendorPayoutCustomRangeProvider);
  final dates = _periodDates(period, customRange);
  final db = adminClient;

  final startStr = dates.start.toIso8601String();
  final endStr = dates.end.toIso8601String();

  // Fetch all vendors
  final vendors = await db
      .from('vendors')
      .select('id, shop_name')
      .eq('is_approved', true)
      .order('shop_name');

  // Fetch delivered orders in period
  final orders = await db
      .from('orders')
      .select('vendor_id, final_amount')
      .eq('status', 'delivered')
      .gte('delivered_at', startStr)
      .lte('delivered_at', endStr);

  // Fetch payouts in period
  final payouts = await db
      .from('payouts')
      .select()
      .eq('payee_type', 'vendor')
      .gte('created_at', startStr)
      .lte('created_at', endStr);

  // Group orders by vendor
  final vendorOrders = <String, List<Map<String, dynamic>>>{};
  for (final o in orders) {
    final vid = o['vendor_id'] as String?;
    if (vid != null) {
      vendorOrders.putIfAbsent(vid, () => []).add(o as Map<String, dynamic>);
    }
  }

  // Group payouts by vendor
  final vendorPayouts = <String, List<Map<String, dynamic>>>{};
  for (final p in payouts) {
    final vid = p['payee_id'] as String?;
    if (vid != null) {
      vendorPayouts.putIfAbsent(vid, () => []).add(p as Map<String, dynamic>);
    }
  }

  const commissionRate = 0.10; // 10% platform commission
  var totalGmv = 0.0;
  var totalCommission = 0.0;
  var totalPaid = 0.0;
  var totalPending = 0.0;

  final rows = <VendorPayoutRow>[];

  for (final v in vendors) {
    final vid = v['id'] as String;
    final shopName = v['shop_name'] as String? ?? '';
    final vOrders = vendorOrders[vid] ?? [];
    final vPayouts = vendorPayouts[vid] ?? [];

    if (vOrders.isEmpty && vPayouts.isEmpty) continue;

    var gross = 0.0;
    for (final o in vOrders) {
      gross += ((o['final_amount'] as num?) ?? 0).toDouble();
    }

    final commission = gross * commissionRate;
    final net = gross - commission;

    var paid = 0.0;
    String? lastPaidDate;
    for (final p in vPayouts) {
      if (p['status'] == 'paid') {
        paid += ((p['net_amount'] as num?) ?? 0).toDouble();
        final paidAt = p['paid_at']?.toString();
        if (paidAt != null) {
          final dt = DateTime.tryParse(paidAt);
          if (dt != null) {
            lastPaidDate = formatDate(dt);
          }
        }
      }
    }

    final pending = net - paid;
    final status = paid >= net
        ? 'paid'
        : paid > 0
            ? 'partial'
            : 'pending';

    totalGmv += gross;
    totalCommission += commission;
    totalPaid += paid;
    totalPending += pending > 0 ? pending : 0;

    rows.add(VendorPayoutRow(
      vendorId: vid,
      shopName: shopName,
      orderCount: vOrders.length,
      grossAmount: gross,
      commissionAmount: commission,
      netAmount: net,
      lastPaidDate: lastPaidDate,
      status: status,
    ));
  }

  // Sort by net descending
  rows.sort((a, b) => b.netAmount.compareTo(a.netAmount));

  return VendorPayoutsSummary(
    totalGmv: totalGmv,
    totalCommission: totalCommission,
    totalToPay: totalGmv - totalCommission,
    totalPaid: totalPaid,
    totalPending: totalPending,
    rows: rows,
  );
});

// ── Mark paid action ────────────────────────────────────────────

final vendorPayoutActionsProvider =
    NotifierProvider<VendorPayoutActionsNotifier, void>(
  VendorPayoutActionsNotifier.new,
);

class VendorPayoutActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markPaid({
    required String vendorId,
    required double grossAmount,
    required double commissionAmount,
    required double netAmount,
    String? paymentReference,
  }) async {
    final period = ref.read(vendorPayoutPeriodProvider);
    final customRange = ref.read(vendorPayoutCustomRangeProvider);
    final dates = _periodDates(period, customRange);

    await adminClient.from('payouts').insert({
      'payee_type': 'vendor',
      'payee_id': vendorId,
      'period_start': dates.start.toIso8601String().split('T')[0],
      'period_end': dates.end.toIso8601String().split('T')[0],
      'gross_amount': grossAmount,
      'commission_amount': commissionAmount,
      'net_amount': netAmount,
      'status': 'paid',
      'payment_reference': paymentReference,
      'paid_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(vendorPayoutsProvider);
  }
}
