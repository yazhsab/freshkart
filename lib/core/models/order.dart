import 'profile.dart';
import 'vendor.dart';
import 'order_item.dart';

class Order {
  final String id;
  final String? orderNumber;
  final String? customerId;
  final String? vendorId;
  final String? deliveryAgentId;
  final String status;
  final double totalAmount;
  final double deliveryFee;
  final double discountAmount;
  final double finalAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final Map<String, dynamic>? deliveryAddress;
  final String? deliveryOtp;
  final String? specialInstructions;
  final String? cancelledBy;
  final String? cancelReason;
  final DateTime? vendorConfirmedAt;
  final DateTime? packedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;
  final Profile? customer;
  final Vendor? vendor;
  final Profile? agent;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.orderNumber,
    this.customerId,
    this.vendorId,
    this.deliveryAgentId,
    required this.status,
    required this.totalAmount,
    this.deliveryFee = 30,
    this.discountAmount = 0,
    required this.finalAmount,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.deliveryAddress,
    this.deliveryOtp,
    this.specialInstructions,
    this.cancelledBy,
    this.cancelReason,
    this.vendorConfirmedAt,
    this.packedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.createdAt,
    this.customer,
    this.vendor,
    this.agent,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String?,
      customerId: json['customer_id'] as String?,
      vendorId: json['vendor_id'] as String?,
      deliveryAgentId: json['delivery_agent_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 30,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      deliveryAddress: json['delivery_address'] as Map<String, dynamic>?,
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      customer: json['customer'] != null
          ? Profile.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      vendor: json['vendors'] != null
          ? Vendor.fromJson(json['vendors'] as Map<String, dynamic>)
          : null,
      agent: json['agent'] != null
          ? Profile.fromJson(json['agent'] as Map<String, dynamic>)
          : null,
      items: (json['order_items'] as List<dynamic>?)
              ?.map(
                  (e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
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
        'delivery_address': deliveryAddress,
        'special_instructions': specialInstructions,
      };

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
