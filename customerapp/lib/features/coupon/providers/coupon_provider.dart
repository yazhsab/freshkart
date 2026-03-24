import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/coupon_model.dart';

class CouponState {
  final bool isLoading;
  final List<CouponModel> coupons;
  final CouponModel? appliedCoupon;
  final double? discountAmount;
  final String? error;

  CouponState({this.isLoading = false, this.coupons = const [], this.appliedCoupon, this.discountAmount, this.error});

  CouponState copyWith({bool? isLoading, List<CouponModel>? coupons, CouponModel? appliedCoupon, double? discountAmount, String? error, bool clearCoupon = false}) =>
    CouponState(
      isLoading: isLoading ?? this.isLoading,
      coupons: coupons ?? this.coupons,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      discountAmount: clearCoupon ? null : (discountAmount ?? this.discountAmount),
      error: error,
    );
}

class CouponNotifier extends StateNotifier<CouponState> {
  CouponNotifier() : super(CouponState());

  final _api = ApiClient.instance;

  Future<void> fetchCoupons({String? vendorId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final query = vendorId != null ? '?vendor_id=$vendorId' : '';
      final response = await _api.get('/api/v1/coupons$query');
      final list = (response.data['data'] as List)
          .map((e) => CouponModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, coupons: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> applyCoupon(String code, double subtotal, String vendorId) async {
    try {
      final response = await _api.post('/api/v1/coupons/apply', data: {
        'code': code,
        'subtotal': subtotal,
        'vendor_id': vendorId,
      });
      final data = response.data['data'];
      state = state.copyWith(
        appliedCoupon: CouponModel.fromJson({
          'id': data['coupon_id'],
          'code': data['code'],
          'title': data['title'],
          'title_tamil': data['title_tamil'],
          'discount_type': data['discount_type'],
          'discount_value': data['discount_value'],
        }),
        discountAmount: (data['discount_amount'] as num).toDouble(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }
}

final couponProvider = StateNotifierProvider<CouponNotifier, CouponState>(
  (ref) => CouponNotifier(),
);
