import 'address_model.dart';
import 'vendor_model.dart';
import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String vendorId;
  final String? deliveryAgentId;
  final String status;
  final double totalAmount;
  final double deliveryFee;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? razorpayOrderId;
  final AddressModel? deliveryAddress;
  final String? deliveryOtp;
  final String? specialInstructions;
  final String? cancelledBy;
  final String? cancelReason;
  final DateTime? vendorConfirmedAt;
  final DateTime? packedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final VendorModel? vendor;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.vendorId,
    this.deliveryAgentId,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.deliveryAddress,
    this.deliveryOtp,
    this.specialInstructions,
    this.cancelledBy,
    this.cancelReason,
    this.vendorConfirmedAt,
    this.packedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.createdAt,
    this.vendor,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      deliveryAgentId: json['delivery_agent_id'] as String?,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      finalAmount: (json['final_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      deliveryAddress: json['delivery_address'] != null
          ? AddressModel.fromJson(
              json['delivery_address'] as Map<String, dynamic>)
          : null,
      deliveryOtp: json['delivery_otp'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      vendorConfirmedAt: json['vendor_confirmed_at'] != null
          ? DateTime.parse(json['vendor_confirmed_at'] as String)
          : null,
      packedAt: json['packed_at'] != null
          ? DateTime.parse(json['packed_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      vendor: json['vendor'] != null
          ? VendorModel.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((e) =>
                  OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'delivery_agent_id': deliveryAgentId,
      'status': status,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'razorpay_order_id': razorpayOrderId,
      'delivery_address': deliveryAddress?.toJson(),
      'delivery_otp': deliveryOtp,
      'special_instructions': specialInstructions,
      'cancelled_by': cancelledBy,
      'cancel_reason': cancelReason,
      'vendor_confirmed_at': vendorConfirmedAt?.toIso8601String(),
      'packed_at': packedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'vendor': vendor?.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? vendorId,
    String? deliveryAgentId,
    String? status,
    double? totalAmount,
    double? deliveryFee,
    double? discountAmount,
    double? finalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? razorpayOrderId,
    AddressModel? deliveryAddress,
    String? deliveryOtp,
    String? specialInstructions,
    String? cancelledBy,
    String? cancelReason,
    DateTime? vendorConfirmedAt,
    DateTime? packedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? createdAt,
    VendorModel? vendor,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      deliveryAgentId: deliveryAgentId ?? this.deliveryAgentId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      vendorConfirmedAt: vendorConfirmedAt ?? this.vendorConfirmedAt,
      packedAt: packedAt ?? this.packedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      vendor: vendor ?? this.vendor,
      items: items ?? this.items,
    );
  }
}
