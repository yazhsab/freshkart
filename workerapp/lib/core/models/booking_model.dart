import 'package:intl/intl.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerCity;
  final String? customerPincode;
  final double? customerLat;
  final double? customerLng;
  final String? workerId;
  final String serviceId;
  final String? serviceName;
  final String status;
  final DateTime scheduledDate;
  final String slotStart;
  final String slotEnd;
  final double baseAmount;
  final double? additionalCharges;
  final double? totalAmount;
  final double? workerEarnings;
  final String paymentMethod;
  final String paymentStatus;
  final String? checkinOtp;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final String? notes;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String? signatureUrl;
  final double? customerRating;
  final String? customerReview;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerCity,
    this.customerPincode,
    this.customerLat,
    this.customerLng,
    this.workerId,
    required this.serviceId,
    this.serviceName,
    required this.status,
    required this.scheduledDate,
    required this.slotStart,
    required this.slotEnd,
    required this.baseAmount,
    this.additionalCharges,
    this.totalAmount,
    this.workerEarnings,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.checkinOtp,
    this.checkinTime,
    this.checkoutTime,
    this.notes,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.signatureUrl,
    this.customerRating,
    this.customerReview,
    this.createdAt,
  });

  bool get isUpcoming => ['pending', 'assigned', 'confirmed'].contains(status);
  bool get isActive => ['on_way', 'in_progress'].contains(status);
  bool get isPast => ['completed', 'cancelled', 'disputed'].contains(status);
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get slotFormatted {
    try {
      final start = _parseTime(slotStart);
      final end = _parseTime(slotEnd);
      final fmt = DateFormat('h:mm a');
      return '${fmt.format(start)} - ${fmt.format(end)}';
    } catch (_) {
      return '$slotStart - $slotEnd';
    }
  }

  int get durationMinutes {
    if (checkinTime != null && checkoutTime != null) {
      return checkoutTime!.difference(checkinTime!).inMinutes;
    }
    try {
      final start = _parseTime(slotStart);
      final end = _parseTime(slotEnd);
      return end.difference(start).inMinutes;
    } catch (_) {
      return 60;
    }
  }

  String get areaOnly {
    if (customerAddress == null) return '';
    final parts = customerAddress!.split(',');
    return parts.length > 1
        ? parts[parts.length - 2].trim()
        : parts.first.trim();
  }

  double get displayAmount => totalAmount ?? baseAmount;

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerAddress: json['customer_address'] as String?,
      customerCity: json['customer_city'] as String?,
      customerPincode: json['customer_pincode'] as String?,
      customerLat: (json['customer_lat'] as num?)?.toDouble(),
      customerLng: (json['customer_lng'] as num?)?.toDouble(),
      workerId: json['worker_id'] as String?,
      serviceId: json['service_id'] as String,
      serviceName: json['service_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      slotStart: json['slot_start'] as String? ?? '09:00',
      slotEnd: json['slot_end'] as String? ?? '10:00',
      baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0,
      additionalCharges: (json['additional_charges'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      workerEarnings: (json['worker_earnings'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      checkinOtp: json['checkin_otp'] as String?,
      checkinTime: json['checkin_time'] != null
          ? DateTime.parse(json['checkin_time'] as String)
          : null,
      checkoutTime: json['checkout_time'] != null
          ? DateTime.parse(json['checkout_time'] as String)
          : null,
      notes: json['notes'] as String?,
      beforePhotos:
          (json['before_photos'] as List<dynamic>?)?.cast<String>() ?? [],
      afterPhotos:
          (json['after_photos'] as List<dynamic>?)?.cast<String>() ?? [],
      signatureUrl: json['signature_url'] as String?,
      customerRating: (json['customer_rating'] as num?)?.toDouble(),
      customerReview: json['customer_review'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'worker_id': workerId,
    'service_id': serviceId,
    'status': status,
    'scheduled_date': scheduledDate.toIso8601String().split('T').first,
    'slot_start': slotStart,
    'slot_end': slotEnd,
    'base_amount': baseAmount,
    'additional_charges': additionalCharges,
    'total_amount': totalAmount,
    'worker_earnings': workerEarnings,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'notes': notes,
    'before_photos': beforePhotos,
    'after_photos': afterPhotos,
    'signature_url': signatureUrl,
  };

  BookingModel copyWith({
    String? status,
    String? workerId,
    double? additionalCharges,
    double? totalAmount,
    double? workerEarnings,
    String? paymentStatus,
    DateTime? checkinTime,
    DateTime? checkoutTime,
    String? notes,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? signatureUrl,
  }) {
    return BookingModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerCity: customerCity,
      customerPincode: customerPincode,
      customerLat: customerLat,
      customerLng: customerLng,
      workerId: workerId ?? this.workerId,
      serviceId: serviceId,
      serviceName: serviceName,
      status: status ?? this.status,
      scheduledDate: scheduledDate,
      slotStart: slotStart,
      slotEnd: slotEnd,
      baseAmount: baseAmount,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      totalAmount: totalAmount ?? this.totalAmount,
      workerEarnings: workerEarnings ?? this.workerEarnings,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      checkinOtp: checkinOtp,
      checkinTime: checkinTime ?? this.checkinTime,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      notes: notes ?? this.notes,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      customerRating: customerRating,
      customerReview: customerReview,
      createdAt: createdAt,
    );
  }
}
