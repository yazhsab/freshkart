class DeliveryOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String vendorName;
  final String vendorPhone;
  final String vendorAddress;
  final double vendorLat;
  final double vendorLng;
  final String customerName;
  final String customerPhone;
  final String customerArea;
  final String deliveryAddress;
  final double customerLat;
  final double customerLng;
  final double finalAmount;
  final double deliveryFee;
  final String paymentMethod;
  final String paymentStatus;
  final int itemCount;
  final String itemsSummary;
  final String? deliveryOtp;
  final double? distanceToVendor;
  final double? distanceToCustomer;
  final int? estimatedPickupMins;
  final int? estimatedDeliveryMins;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final DateTime? vendorConfirmedAt;
  final double? pickupDistanceKm;
  final double? dropDistanceKm;
  final double? deliveryEarnings;

  const DeliveryOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.vendorName,
    required this.vendorPhone,
    required this.vendorAddress,
    required this.vendorLat,
    required this.vendorLng,
    required this.customerName,
    required this.customerPhone,
    required this.customerArea,
    required this.deliveryAddress,
    required this.customerLat,
    required this.customerLng,
    required this.finalAmount,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.paymentStatus,
    this.itemCount = 0,
    this.itemsSummary = '',
    this.deliveryOtp,
    this.distanceToVendor,
    this.distanceToCustomer,
    this.estimatedPickupMins,
    this.estimatedDeliveryMins,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.createdAt,
    this.cancelledAt,
    this.vendorConfirmedAt,
    this.pickupDistanceKm,
    this.dropDistanceKm,
    this.deliveryEarnings,
  });

  // Computed properties
  bool get isPending => status == 'pending' || status == 'assigned';
  bool get isPickupPhase =>
      status == 'assigned' ||
      status == 'heading_to_vendor' ||
      status == 'at_vendor';
  bool get isDropoffPhase => status == 'picked_up' || status == 'in_transit';
  bool get isDelivered => status == 'delivered';
  bool get isCod => paymentMethod.toLowerCase() == 'cod';
  bool get isCancelled => status == 'cancelled';
  String get vendorFullAddress => vendorAddress;
  String get customerFullAddress => deliveryAddress;

  double get totalDistance =>
      (distanceToVendor ?? 0) + (distanceToCustomer ?? 0);
  int get totalEstimatedMins =>
      (estimatedPickupMins ?? 0) + (estimatedDeliveryMins ?? 0);

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      vendorName: json['vendor_name'] as String? ?? '',
      vendorPhone: json['vendor_phone'] as String? ?? '',
      vendorAddress: json['vendor_address'] as String? ?? '',
      vendorLat: (json['vendor_lat'] as num?)?.toDouble() ?? 0.0,
      vendorLng: (json['vendor_lng'] as num?)?.toDouble() ?? 0.0,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerArea: json['customer_area'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      customerLat: (json['customer_lat'] as num?)?.toDouble() ?? 0.0,
      customerLng: (json['customer_lng'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      itemsSummary: json['items_summary'] as String? ?? '',
      deliveryOtp: json['delivery_otp']?.toString(),
      distanceToVendor: (json['distance_to_vendor'] as num?)?.toDouble(),
      distanceToCustomer: (json['distance_to_customer'] as num?)?.toDouble(),
      estimatedPickupMins: (json['estimated_pickup_mins'] as num?)?.toInt(),
      estimatedDeliveryMins: (json['estimated_delivery_mins'] as num?)?.toInt(),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
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
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      vendorConfirmedAt: json['vendor_confirmed_at'] != null
          ? DateTime.parse(json['vendor_confirmed_at'] as String)
          : null,
      pickupDistanceKm: (json['pickup_distance_km'] as num?)?.toDouble(),
      dropDistanceKm: (json['drop_distance_km'] as num?)?.toDouble(),
      deliveryEarnings: (json['delivery_earnings'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'vendor_name': vendorName,
      'vendor_phone': vendorPhone,
      'vendor_address': vendorAddress,
      'vendor_lat': vendorLat,
      'vendor_lng': vendorLng,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_area': customerArea,
      'delivery_address': deliveryAddress,
      'customer_lat': customerLat,
      'customer_lng': customerLng,
      'final_amount': finalAmount,
      'delivery_fee': deliveryFee,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'item_count': itemCount,
      'items_summary': itemsSummary,
      'delivery_otp': deliveryOtp,
      'distance_to_vendor': distanceToVendor,
      'distance_to_customer': distanceToCustomer,
      'estimated_pickup_mins': estimatedPickupMins,
      'estimated_delivery_mins': estimatedDeliveryMins,
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'vendor_confirmed_at': vendorConfirmedAt?.toIso8601String(),
      'pickup_distance_km': pickupDistanceKm,
      'drop_distance_km': dropDistanceKm,
      'delivery_earnings': deliveryEarnings,
    };
  }

  DeliveryOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? status,
    String? vendorName,
    String? vendorPhone,
    String? vendorAddress,
    double? vendorLat,
    double? vendorLng,
    String? customerName,
    String? customerPhone,
    String? customerArea,
    String? deliveryAddress,
    double? customerLat,
    double? customerLng,
    double? finalAmount,
    double? deliveryFee,
    String? paymentMethod,
    String? paymentStatus,
    int? itemCount,
    String? itemsSummary,
    String? deliveryOtp,
    double? distanceToVendor,
    double? distanceToCustomer,
    int? estimatedPickupMins,
    int? estimatedDeliveryMins,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? createdAt,
    DateTime? cancelledAt,
    DateTime? vendorConfirmedAt,
    double? pickupDistanceKm,
    double? dropDistanceKm,
    double? deliveryEarnings,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      vendorName: vendorName ?? this.vendorName,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorLat: vendorLat ?? this.vendorLat,
      vendorLng: vendorLng ?? this.vendorLng,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerArea: customerArea ?? this.customerArea,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      finalAmount: finalAmount ?? this.finalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      itemCount: itemCount ?? this.itemCount,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      distanceToVendor: distanceToVendor ?? this.distanceToVendor,
      distanceToCustomer: distanceToCustomer ?? this.distanceToCustomer,
      estimatedPickupMins: estimatedPickupMins ?? this.estimatedPickupMins,
      estimatedDeliveryMins:
          estimatedDeliveryMins ?? this.estimatedDeliveryMins,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      vendorConfirmedAt: vendorConfirmedAt ?? this.vendorConfirmedAt,
      pickupDistanceKm: pickupDistanceKm ?? this.pickupDistanceKm,
      dropDistanceKm: dropDistanceKm ?? this.dropDistanceKm,
      deliveryEarnings: deliveryEarnings ?? this.deliveryEarnings,
    );
  }
}
