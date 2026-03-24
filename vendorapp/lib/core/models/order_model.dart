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
  final Map<String, dynamic>? deliveryAddress;
  final String? deliveryOtp;
  final String? specialInstructions;
  final String? cancelledBy;
  final String? cancelReason;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAgentName;
  final String? deliveryAgentPhone;
  final DateTime? vendorConfirmedAt;
  final DateTime? packedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
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
    this.customerName,
    this.customerPhone,
    this.deliveryAgentName,
    this.deliveryAgentPhone,
    this.vendorConfirmedAt,
    this.packedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.createdAt,
    this.items = const [],
  });

  String get customerFirstName {
    final name = customerName ?? '';
    if (name.isEmpty) return 'Customer';
    return name.split(' ').first;
  }

  String get customerArea {
    if (deliveryAddress == null) return 'Unknown area';
    return deliveryAddress!['area'] as String? ??
        deliveryAddress!['locality'] as String? ??
        'Unknown area';
  }

  int get itemCount => items.length;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPacking => status == 'packing';
  bool get isReady => status == 'ready';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  bool get isActive => status == 'confirmed' || status == 'packing';

  bool get isDone => status == 'delivered' || status == 'cancelled';

  bool get isPaidOnline => paymentMethod == 'online' || paymentMethod == 'upi';

  double get vendorEarnings {
    if (isCancelled) return 0;
    return totalAmount;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? '',
      deliveryAgentId: json['delivery_agent_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      razorpayOrderId: json['razorpay_order_id'] as String?,
      deliveryAddress: json['delivery_address'] is Map
          ? Map<String, dynamic>.from(json['delivery_address'] as Map)
          : null,
      deliveryOtp: json['delivery_otp']?.toString(),
      specialInstructions: json['special_instructions'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      customerName:
          json['customer_name'] as String? ??
          json['customer']?['full_name'] as String?,
      customerPhone:
          json['customer_phone'] as String? ??
          json['customer']?['phone'] as String?,
      deliveryAgentName:
          json['delivery_agent_name'] as String? ??
          json['delivery_agent']?['full_name'] as String?,
      deliveryAgentPhone:
          json['delivery_agent_phone'] as String? ??
          json['delivery_agent']?['phone'] as String?,
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
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
                .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
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
      'delivery_address': deliveryAddress,
      'delivery_otp': deliveryOtp,
      'special_instructions': specialInstructions,
      'cancelled_by': cancelledBy,
      'cancel_reason': cancelReason,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_agent_name': deliveryAgentName,
      'delivery_agent_phone': deliveryAgentPhone,
      'vendor_confirmed_at': vendorConfirmedAt?.toIso8601String(),
      'packed_at': packedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
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
    Map<String, dynamic>? deliveryAddress,
    String? deliveryOtp,
    String? specialInstructions,
    String? cancelledBy,
    String? cancelReason,
    String? customerName,
    String? customerPhone,
    String? deliveryAgentName,
    String? deliveryAgentPhone,
    DateTime? vendorConfirmedAt,
    DateTime? packedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? createdAt,
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
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAgentName: deliveryAgentName ?? this.deliveryAgentName,
      deliveryAgentPhone: deliveryAgentPhone ?? this.deliveryAgentPhone,
      vendorConfirmedAt: vendorConfirmedAt ?? this.vendorConfirmedAt,
      packedAt: packedAt ?? this.packedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
