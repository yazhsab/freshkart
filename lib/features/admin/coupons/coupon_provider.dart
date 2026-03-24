import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── State ────────────────────────────────────────────────────────

class CouponListState {
  const CouponListState({
    this.coupons = const [],
    this.filter = 'All',
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<CouponRow> coupons;
  final String filter;
  final String searchQuery;
  final bool isLoading;

  CouponListState copyWith({
    List<CouponRow>? coupons,
    String? filter,
    String? searchQuery,
    bool? isLoading,
  }) {
    return CouponListState(
      coupons: coupons ?? this.coupons,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<CouponRow> get filteredCoupons {
    var result = coupons;

    // Apply status filter
    switch (filter) {
      case 'Active':
        result = result.where((c) => c.isActive).toList();
      case 'Inactive':
        result = result.where((c) => !c.isActive).toList();
      case 'Vendor':
        result = result.where((c) => c.vendorId != null).toList();
      case 'Platform':
        result = result.where((c) => c.vendorId == null).toList();
      case 'Percentage':
        result = result.where((c) => c.discountType == 'percentage').toList();
      case 'Flat':
        result = result.where((c) => c.discountType == 'flat').toList();
      default:
        break;
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((c) {
        return c.code.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            (c.vendorName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }
}

// ── Coupon row model (flat) ──────────────────────────────────────

class CouponRow {
  const CouponRow({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.usedCount = 0,
    this.usageLimit,
    this.isActive = true,
    this.vendorId,
    this.vendorName,
    this.startsAt,
    this.expiresAt,
    this.createdAt,
    this.revenueImpact = 0,
  });

  final String id;
  final String code;
  final String title;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int usedCount;
  final int? usageLimit;
  final bool isActive;
  final String? vendorId;
  final String? vendorName;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final double revenueImpact;

  String get discountLabel {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return '\u20B9${discountValue.toStringAsFixed(0)}';
  }

  String get typeLabel =>
      discountType == 'percentage' ? 'Percentage' : 'Flat';

  String get scopeLabel => vendorId != null ? 'Vendor' : 'Platform';

  String get usageLabel {
    if (usageLimit != null) {
      return '$usedCount / $usageLimit';
    }
    return '$usedCount';
  }

  factory CouponRow.fromMap(Map<String, dynamic> m) {
    final vendor = m['vendors'] as Map<String, dynamic>?;
    return CouponRow(
      id: m['id'] as String,
      code: m['code'] as String? ?? '',
      title: m['title'] as String? ?? '',
      discountType: m['discount_type'] as String? ?? 'flat',
      discountValue: ((m['discount_value'] as num?) ?? 0).toDouble(),
      minOrderAmount: ((m['min_order_amount'] as num?) ?? 0).toDouble(),
      maxDiscount: (m['max_discount'] as num?)?.toDouble(),
      usedCount: m['used_count'] as int? ?? 0,
      usageLimit: m['usage_limit'] as int?,
      isActive: m['is_active'] as bool? ?? true,
      vendorId: m['vendor_id'] as String?,
      vendorName: vendor?['shop_name'] as String?,
      startsAt: m['starts_at'] != null
          ? DateTime.tryParse(m['starts_at'].toString())
          : null,
      expiresAt: m['expires_at'] != null
          ? DateTime.tryParse(m['expires_at'].toString())
          : null,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
      revenueImpact: ((m['revenue_impact'] as num?) ?? 0).toDouble(),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────

final couponListProvider =
    NotifierProvider<CouponListNotifier, CouponListState>(
  CouponListNotifier.new,
);

class CouponListNotifier extends Notifier<CouponListState> {
  @override
  CouponListState build() {
    fetchCoupons();
    return const CouponListState(isLoading: true);
  }

  Future<void> fetchCoupons() async {
    state = state.copyWith(isLoading: true);
    try {
      final rows = await adminClient
          .from('coupons')
          .select(
            '*, vendors(id, shop_name)',
          )
          .order('created_at', ascending: false);

      final coupons = (rows as List)
          .map((row) => CouponRow.fromMap(row as Map<String, dynamic>))
          .toList();

      state = state.copyWith(coupons: coupons, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createCoupon(Map<String, dynamic> data) async {
    await adminClient.from('coupons').insert(data);
    await fetchCoupons();
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    await adminClient.from('coupons').update(data).eq('id', id);
    await fetchCoupons();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await adminClient
        .from('coupons')
        .update({'is_active': isActive}).eq('id', id);
    await fetchCoupons();
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
