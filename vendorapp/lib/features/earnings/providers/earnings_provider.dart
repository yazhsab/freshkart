import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class DailyRevenuePoint {
  final DateTime date;
  final double amount;

  const DailyRevenuePoint({required this.date, required this.amount});
}

class TopProduct {
  final String name;
  final int unitsSold;
  final double revenue;

  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });
}

class PayoutModel {
  final String id;
  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final String status; // 'pending' | 'processing' | 'paid'
  final DateTime? paidOn;
  final String? referenceNumber;
  final String? bankName;
  final String? accountLast4;
  final List<PayoutOrderItem> orders;

  const PayoutModel({
    required this.id,
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.status,
    this.paidOn,
    this.referenceNumber,
    this.bankName,
    this.accountLast4,
    this.orders = const [],
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['period_start'] ?? json['created_at']);
    final end = DateTime.parse(json['period_end'] ?? json['created_at']);
    final fmt = DateFormat('dd MMM');
    final periodLabel = 'Week of ${fmt.format(start)} - ${fmt.format(end)}';

    final gross = (json['gross_amount'] ?? 0).toDouble();
    final commission = (json['commission_amount'] ?? 0).toDouble();
    final net = (json['net_amount'] ?? gross - commission).toDouble();

    final ordersList =
        (json['orders'] as List?)
            ?.map((o) => PayoutOrderItem.fromJson(o))
            .toList() ??
        [];

    return PayoutModel(
      id: json['id']?.toString() ?? '',
      periodLabel: json['period_label'] ?? periodLabel,
      periodStart: start,
      periodEnd: end,
      grossAmount: gross,
      commissionAmount: commission,
      netAmount: net,
      status: json['status'] ?? 'pending',
      paidOn: json['paid_on'] != null ? DateTime.parse(json['paid_on']) : null,
      referenceNumber: json['reference_number'],
      bankName: json['bank_name'],
      accountLast4: json['account_last4'],
      orders: ordersList,
    );
  }
}

class PayoutOrderItem {
  final String orderId;
  final String orderNumber;
  final double amount;
  final double commission;
  final String status;
  final DateTime createdAt;

  const PayoutOrderItem({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.commission,
    required this.status,
    required this.createdAt,
  });

  factory PayoutOrderItem.fromJson(Map<String, dynamic> json) {
    return PayoutOrderItem(
      orderId: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      amount: (json['total_amount'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class EarningsState {
  final String period; // 'today' | 'week' | 'month'
  final double grossRevenue;
  final double deliveryFeesCollected;
  final double platformCommission;
  final double netEarnings;
  final int orderCount;
  final double avgOrderValue;
  final int cancellationCount;
  final double cancellationRate;
  final List<DailyRevenuePoint> dailyRevenue;
  final List<TopProduct> topProducts;
  final Map<String, double> paymentMethodBreakdown;
  final int deliveredCount;
  final bool isLoading;
  final String? error;

  const EarningsState({
    this.period = 'today',
    this.grossRevenue = 0,
    this.deliveryFeesCollected = 0,
    this.platformCommission = 0,
    this.netEarnings = 0,
    this.orderCount = 0,
    this.avgOrderValue = 0,
    this.cancellationCount = 0,
    this.cancellationRate = 0,
    this.dailyRevenue = const [],
    this.topProducts = const [],
    this.paymentMethodBreakdown = const {'upi': 0, 'card': 0, 'cod': 0},
    this.deliveredCount = 0,
    this.isLoading = true,
    this.error,
  });

  EarningsState copyWith({
    String? period,
    double? grossRevenue,
    double? deliveryFeesCollected,
    double? platformCommission,
    double? netEarnings,
    int? orderCount,
    double? avgOrderValue,
    int? cancellationCount,
    double? cancellationRate,
    List<DailyRevenuePoint>? dailyRevenue,
    List<TopProduct>? topProducts,
    Map<String, double>? paymentMethodBreakdown,
    int? deliveredCount,
    bool? isLoading,
    String? error,
  }) {
    return EarningsState(
      period: period ?? this.period,
      grossRevenue: grossRevenue ?? this.grossRevenue,
      deliveryFeesCollected:
          deliveryFeesCollected ?? this.deliveryFeesCollected,
      platformCommission: platformCommission ?? this.platformCommission,
      netEarnings: netEarnings ?? this.netEarnings,
      orderCount: orderCount ?? this.orderCount,
      avgOrderValue: avgOrderValue ?? this.avgOrderValue,
      cancellationCount: cancellationCount ?? this.cancellationCount,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      topProducts: topProducts ?? this.topProducts,
      paymentMethodBreakdown:
          paymentMethodBreakdown ?? this.paymentMethodBreakdown,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class EarningsNotifier extends StateNotifier<EarningsState> {
  final Dio _dio;

  EarningsNotifier(this._dio) : super(const EarningsState());

  /// Fetch earnings for the given vendor and period.
  Future<void> fetchEarnings(String vendorId, String period) async {
    state = state.copyWith(isLoading: true, error: null, period: period);

    try {
      final now = DateTime.now();
      late DateTime dateFrom;
      late DateTime dateTo;

      switch (period) {
        case 'today':
          dateFrom = DateTime(now.year, now.month, now.day);
          dateTo = now;
          break;
        case 'week':
          dateFrom = now.subtract(Duration(days: now.weekday - 1));
          dateFrom = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
          dateTo = now;
          break;
        case 'month':
          dateFrom = DateTime(now.year, now.month, 1);
          dateTo = now;
          break;
        default:
          dateFrom = DateTime(now.year, now.month, now.day);
          dateTo = now;
      }

      final dateFormat = DateFormat('yyyy-MM-dd');
      final response = await _dio.get(
        VendorApiEndpoints.vendorOrders,
        queryParameters: {
          'date_from': dateFormat.format(dateFrom),
          'date_to': dateFormat.format(dateTo),
        },
      );

      final orders = (response.data['data'] as List?) ?? [];
      _computeStats(orders, period, dateFrom, dateTo);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Switch the selected period and re-fetch.
  Future<void> changePeriod(String period) async {
    final vendorId = SupabaseConfig.currentUser?.id ?? '';
    await fetchEarnings(vendorId, period);
  }

  // ---- private computation ------------------------------------------------

  void _computeStats(
    List<dynamic> orders,
    String period,
    DateTime dateFrom,
    DateTime dateTo,
  ) {
    double gross = 0;
    double deliveryFees = 0;
    int delivered = 0;
    int cancelled = 0;
    int totalOrders = orders.length;

    // Payment method accumulators
    double upiTotal = 0;
    double cardTotal = 0;
    double codTotal = 0;

    // Product aggregation
    final productMap = <String, _ProductAccum>{};

    // Daily revenue aggregation
    final dailyMap = <String, double>{};

    for (final o in orders) {
      final status = o['status']?.toString() ?? '';
      final amount = (o['total_amount'] ?? 0).toDouble();
      final delivery = (o['delivery_fee'] ?? 0).toDouble();
      final paymentMethod = (o['payment_method'] ?? 'cod')
          .toString()
          .toLowerCase();
      final createdAt =
          DateTime.tryParse(o['created_at'] ?? '') ?? DateTime.now();
      final dayKey = DateFormat('yyyy-MM-dd').format(createdAt);

      if (status == 'cancelled') {
        cancelled++;
        continue;
      }

      gross += amount;
      deliveryFees += delivery;
      delivered++;

      // Payment method
      switch (paymentMethod) {
        case 'upi':
          upiTotal += amount;
          break;
        case 'card':
        case 'credit_card':
        case 'debit_card':
          cardTotal += amount;
          break;
        default:
          codTotal += amount;
      }

      // Daily revenue
      dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + amount;

      // Products
      final items = o['items'] as List? ?? [];
      for (final item in items) {
        final productName = item['product_name']?.toString() ?? 'Unknown';
        final qty = (item['quantity'] ?? 1) as int;
        final itemTotal = (item['total'] ?? item['price'] ?? 0).toDouble();
        if (productMap.containsKey(productName)) {
          productMap[productName]!.unitsSold += qty;
          productMap[productName]!.revenue += itemTotal;
        } else {
          productMap[productName] = _ProductAccum(
            name: productName,
            unitsSold: qty,
            revenue: itemTotal,
          );
        }
      }
    }

    // Commission
    final commission = gross * (VendorAppConfig.platformCommissionPct / 100);
    final net = gross - commission;
    final avg = delivered > 0 ? gross / delivered : 0.0;
    final cancelRate = totalOrders > 0 ? (cancelled / totalOrders) * 100 : 0.0;

    // Payment method percentages
    final paymentTotal = upiTotal + cardTotal + codTotal;
    final paymentBreakdown = <String, double>{
      'upi': paymentTotal > 0 ? (upiTotal / paymentTotal) * 100 : 0,
      'card': paymentTotal > 0 ? (cardTotal / paymentTotal) * 100 : 0,
      'cod': paymentTotal > 0 ? (codTotal / paymentTotal) * 100 : 0,
    };

    // Build daily revenue list (fill gaps)
    final dailyRevenue = <DailyRevenuePoint>[];
    var cursor = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final endDate = DateTime(dateTo.year, dateTo.month, dateTo.day);
    while (!cursor.isAfter(endDate)) {
      final key = DateFormat('yyyy-MM-dd').format(cursor);
      dailyRevenue.add(
        DailyRevenuePoint(date: cursor, amount: dailyMap[key] ?? 0),
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    // Top products sorted by revenue
    final sortedProducts = productMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final topProducts = sortedProducts
        .take(5)
        .map(
          (p) => TopProduct(
            name: p.name,
            unitsSold: p.unitsSold,
            revenue: p.revenue,
          ),
        )
        .toList();

    state = state.copyWith(
      period: period,
      grossRevenue: gross,
      deliveryFeesCollected: deliveryFees,
      platformCommission: commission,
      netEarnings: net,
      orderCount: totalOrders,
      avgOrderValue: avg,
      cancellationCount: cancelled,
      cancellationRate: cancelRate,
      dailyRevenue: dailyRevenue,
      topProducts: topProducts,
      paymentMethodBreakdown: paymentBreakdown,
      deliveredCount: delivered,
      isLoading: false,
      error: null,
    );
  }
}

/// Mutable helper for product aggregation during computation.
class _ProductAccum {
  final String name;
  int unitsSold;
  double revenue;

  _ProductAccum({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final earningsProvider = StateNotifierProvider<EarningsNotifier, EarningsState>(
  (ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:3000',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization':
              'Bearer ${SupabaseConfig.currentSession?.accessToken ?? ''}',
        },
      ),
    );
    return EarningsNotifier(dio);
  },
);

/// Fetches payout list for the current vendor.
final payoutsProvider = FutureProvider<List<PayoutModel>>((ref) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'http://localhost:3000',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            'Bearer ${SupabaseConfig.currentSession?.accessToken ?? ''}',
      },
    ),
  );

  try {
    final response = await dio.get(VendorApiEndpoints.payoutsVendor);
    final payouts = (response.data['data'] as List?) ?? [];
    return payouts.map((p) => PayoutModel.fromJson(p)).toList();
  } catch (e) {
    return [];
  }
});

/// Provides a single payout by ID from the cached payouts list.
final payoutByIdProvider = Provider.family<PayoutModel?, String>((
  ref,
  payoutId,
) {
  final payoutsAsync = ref.watch(payoutsProvider);
  return payoutsAsync.whenOrNull(
    data: (payouts) {
      try {
        return payouts.firstWhere((p) => p.id == payoutId);
      } catch (_) {
        return null;
      }
    },
  );
});
