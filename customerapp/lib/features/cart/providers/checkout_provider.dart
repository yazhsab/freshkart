import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/address_model.dart';
import 'package:freshkart_customer/core/models/order_model.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';

enum PaymentMethod { upi, card, cod }

class CheckoutState {
  final PaymentMethod selectedPaymentMethod;
  final bool isProcessing;
  final OrderModel? orderResult;
  final String? error;
  final String? couponCode;
  final double walletAmount;
  final int loyaltyPoints;
  final DateTime? scheduledAt;
  final bool useWallet;
  final bool isScheduled;

  const CheckoutState({
    this.selectedPaymentMethod = PaymentMethod.cod,
    this.isProcessing = false,
    this.orderResult,
    this.error,
    this.couponCode,
    this.walletAmount = 0,
    this.loyaltyPoints = 0,
    this.scheduledAt,
    this.useWallet = false,
    this.isScheduled = false,
  });

  CheckoutState copyWith({
    PaymentMethod? selectedPaymentMethod,
    bool? isProcessing,
    OrderModel? orderResult,
    String? error,
    bool clearError = false,
    bool clearOrder = false,
    String? couponCode,
    bool clearCoupon = false,
    double? walletAmount,
    int? loyaltyPoints,
    DateTime? scheduledAt,
    bool clearSchedule = false,
    bool? useWallet,
    bool? isScheduled,
  }) {
    return CheckoutState(
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      orderResult: clearOrder ? null : (orderResult ?? this.orderResult),
      error: clearError ? null : (error ?? this.error),
      couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
      walletAmount: walletAmount ?? this.walletAmount,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
      useWallet: useWallet ?? this.useWallet,
      isScheduled: isScheduled ?? this.isScheduled,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  final _api = ApiClient();

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPaymentMethod: method, clearError: true);
  }

  void setCouponCode(String? code) {
    if (code == null) {
      state = state.copyWith(clearCoupon: true);
    } else {
      state = state.copyWith(couponCode: code);
    }
  }

  void setUseWallet(bool use, {double amount = 0}) {
    state = state.copyWith(useWallet: use, walletAmount: use ? amount : 0);
  }

  void setWalletAmount(double amount) {
    state = state.copyWith(walletAmount: amount);
  }

  void setLoyaltyPoints(int points) {
    state = state.copyWith(loyaltyPoints: points);
  }

  void setScheduled(bool isScheduled) {
    state = state.copyWith(
      isScheduled: isScheduled,
      clearSchedule: !isScheduled,
    );
  }

  void setScheduledAt(DateTime? dateTime) {
    if (dateTime == null) {
      state = state.copyWith(clearSchedule: true);
    } else {
      state = state.copyWith(scheduledAt: dateTime);
    }
  }

  Future<OrderModel> createOrder({
    required CartState cartState,
    required AddressModel address,
    required PaymentMethod paymentMethod,
    String? specialInstructions,
    String? couponCode,
    double walletAmount = 0,
    int loyaltyPoints = 0,
    DateTime? scheduledAt,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final items = cartState.itemsList
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'unit_price': item.product.price,
            },
          )
          .toList();

      final paymentMethodStr = switch (paymentMethod) {
        PaymentMethod.upi => 'upi',
        PaymentMethod.card => 'card',
        PaymentMethod.cod => 'cod',
      };

      final data = {
        'vendor_id': cartState.vendorId,
        'items': items,
        'delivery_address': address.toJson(),
        'payment_method': paymentMethodStr,
        'special_instructions': specialInstructions,
        'total_amount': cartState.subtotal,
        'delivery_fee': cartState.deliveryFee,
        'discount_amount': 0,
        'final_amount': cartState.total,
        if (couponCode != null) 'coupon_code': couponCode,
        if (walletAmount > 0) 'wallet_amount': walletAmount,
        if (loyaltyPoints > 0) 'loyalty_points': loyaltyPoints,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      };

      final response = await _api.post(ApiEndpoints.createOrder, data: data);
      final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(isProcessing: false, orderResult: order);
      return order;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      rethrow;
    }
  }

  /// Creates a Razorpay order on the backend for UPI/Card payments.
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String orderId,
  }) async {
    final response = await _api.post(
      ApiEndpoints.razorpayCreateOrder,
      data: {
        'amount': (amount * 100).round(), // Convert to paise
        'order_id': orderId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Verifies Razorpay payment on the backend.
  Future<OrderModel> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    state = state.copyWith(isProcessing: true);
    try {
      final response = await _api.post(
        ApiEndpoints.razorpayVerify,
        data: {
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
          'order_id': orderId,
        },
      );
      final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(isProcessing: false, orderResult: order);
      return order;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      rethrow;
    }
  }

  void reset() {
    state = const CheckoutState();
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    return CheckoutNotifier();
  },
);
