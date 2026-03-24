import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_vendor/core/api/api_client.dart';

class CouponModel {
  final String id;
  final String code;
  final String title;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double? maxDiscount;
  final double? minOrderAmount;
  final DateTime validFrom;
  final DateTime validUntil;
  final int? perUserLimit;
  final bool isActive;
  final int usageCount;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderAmount,
    required this.validFrom,
    required this.validUntil,
    this.perUserLimit,
    this.isActive = true,
    this.usageCount = 0,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
        id: json['id'],
        code: json['code'],
        title: json['title'],
        discountType: json['discount_type'],
        discountValue: (json['discount_value'] as num).toDouble(),
        maxDiscount: json['max_discount'] != null
            ? (json['max_discount'] as num).toDouble()
            : null,
        minOrderAmount: json['min_order_amount'] != null
            ? (json['min_order_amount'] as num).toDouble()
            : null,
        validFrom: DateTime.parse(json['valid_from']),
        validUntil: DateTime.parse(json['valid_until']),
        perUserLimit: json['per_user_limit'],
        isActive: json['is_active'] ?? true,
        usageCount: json['usage_count'] ?? 0,
      );

  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isUpcoming => DateTime.now().isBefore(validFrom);
}

// Coupons list provider
final couponsProvider =
    StateNotifierProvider<CouponsNotifier, AsyncValue<List<CouponModel>>>(
  (ref) => CouponsNotifier(),
);

class CouponsNotifier extends StateNotifier<AsyncValue<List<CouponModel>>> {
  CouponsNotifier() : super(const AsyncValue.loading()) {
    fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    try {
      state = const AsyncValue.loading();
      final response = await ApiClient.instance.get('/api/vendor/coupons');
      final coupons = (response.data['data'] as List)
          .map((json) => CouponModel.fromJson(json))
          .toList();
      state = AsyncValue.data(coupons);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createCoupon(Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.post('/api/vendor/coupons', data: data);
      await fetchCoupons();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCoupon(String id, Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.patch('/api/vendor/coupons/$id', data: data);
      await fetchCoupons();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCoupon(String id) async {
    try {
      await ApiClient.instance.delete('/api/vendor/coupons/$id');
      await fetchCoupons();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleCouponStatus(String id, bool isActive) async {
    return updateCoupon(id, {'is_active': isActive});
  }
}
