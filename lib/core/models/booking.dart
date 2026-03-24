import 'profile.dart';
import 'worker.dart';
import 'service_category.dart';

class Booking {
  final String id;
  final String? bookingNumber;
  final String? customerId;
  final String? workerId;
  final String? serviceCategoryId;
  final String status;
  final DateTime slotDate;
  final String slotStart;
  final String slotEnd;
  final double? quotedPrice;
  final double? finalPrice;
  final double bookingFee;
  final double? platformCommission;
  final String? paymentMethod;
  final String paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final Map<String, dynamic>? serviceAddress;
  final String? customerNotes;
  final String? workerNotes;
  final String? checkinOtp;
  final DateTime? checkinAt;
  final DateTime? checkoutAt;
  final String? cancelledBy;
  final String? cancelReason;
  final String? disputeReason;
  final DateTime? createdAt;
  final Profile? customer;
  final Worker? worker;
  final ServiceCategory? serviceCategory;

  Booking({
    required this.id,
    this.bookingNumber,
    this.customerId,
    this.workerId,
    this.serviceCategoryId,
    required this.status,
    required this.slotDate,
    required this.slotStart,
    required this.slotEnd,
    this.quotedPrice,
    this.finalPrice,
    this.bookingFee = 99,
    this.platformCommission,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.serviceAddress,
    this.customerNotes,
    this.workerNotes,
    this.checkinOtp,
    this.checkinAt,
    this.checkoutAt,
    this.cancelledBy,
    this.cancelReason,
    this.disputeReason,
    this.createdAt,
    this.customer,
    this.worker,
    this.serviceCategory,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      bookingNumber: json['booking_number'] as String?,
      customerId: json['customer_id'] as String?,
      workerId: json['worker_id'] as String?,
      serviceCategoryId: json['service_category_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      slotDate: DateTime.parse(json['slot_date'] as String),
      slotStart: json['slot_start'] as String,
      slotEnd: json['slot_end'] as String,
      quotedPrice: (json['quoted_price'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      bookingFee: (json['booking_fee'] as num?)?.toDouble() ?? 99,
      platformCommission:
          (json['platform_commission'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      serviceAddress: json['service_address'] as Map<String, dynamic>?,
      customerNotes: json['customer_notes'] as String?,
      workerNotes: json['worker_notes'] as String?,
      checkinOtp: json['checkin_otp'] as String?,
      checkinAt: json['checkin_at'] != null
          ? DateTime.parse(json['checkin_at'] as String)
          : null,
      checkoutAt: json['checkout_at'] != null
          ? DateTime.parse(json['checkout_at'] as String)
          : null,
      cancelledBy: json['cancelled_by'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      disputeReason: json['dispute_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      customer: json['customer'] != null
          ? Profile.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      worker: json['workers'] != null
          ? Worker.fromJson(json['workers'] as Map<String, dynamic>)
          : null,
      serviceCategory: json['service_categories'] != null
          ? ServiceCategory.fromJson(
              json['service_categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'worker_id': workerId,
        'service_category_id': serviceCategoryId,
        'status': status,
        'slot_date': slotDate.toIso8601String().split('T')[0],
        'slot_start': slotStart,
        'slot_end': slotEnd,
        'quoted_price': quotedPrice,
        'final_price': finalPrice,
        'booking_fee': bookingFee,
        'platform_commission': platformCommission,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'service_address': serviceAddress,
        'customer_notes': customerNotes,
      };

  bool get isUnassigned => workerId == null;
}
