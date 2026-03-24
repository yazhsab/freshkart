import 'address_model.dart';
import 'worker_model.dart';
import 'service_category_model.dart';

class BookingModel {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String? workerId;
  final String serviceCategoryId;
  final String status;
  final DateTime slotDate;
  final String slotStart;
  final String slotEnd;
  final double? quotedPrice;
  final double? finalPrice;
  final double bookingFee;
  final String paymentMethod;
  final String paymentStatus;
  final AddressModel? serviceAddress;
  final String? customerNotes;
  final String? workerNotes;
  final String? checkinOtp;
  final DateTime? checkinAt;
  final DateTime? checkoutAt;
  final String? cancelledBy;
  final String? cancelReason;
  final String? disputeReason;
  final DateTime createdAt;
  final WorkerModel? worker;
  final ServiceCategoryModel? serviceCategory;

  const BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    this.workerId,
    required this.serviceCategoryId,
    required this.status,
    required this.slotDate,
    required this.slotStart,
    required this.slotEnd,
    this.quotedPrice,
    this.finalPrice,
    required this.bookingFee,
    required this.paymentMethod,
    required this.paymentStatus,
    this.serviceAddress,
    this.customerNotes,
    this.workerNotes,
    this.checkinOtp,
    this.checkinAt,
    this.checkoutAt,
    this.cancelledBy,
    this.cancelReason,
    this.disputeReason,
    required this.createdAt,
    this.worker,
    this.serviceCategory,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      bookingNumber: json['booking_number'] as String,
      customerId: json['customer_id'] as String,
      workerId: json['worker_id'] as String?,
      serviceCategoryId: json['service_category_id'] as String,
      status: json['status'] as String,
      slotDate: DateTime.parse(json['slot_date'] as String),
      slotStart: json['slot_start'] as String,
      slotEnd: json['slot_end'] as String,
      quotedPrice: (json['quoted_price'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      bookingFee: (json['booking_fee'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      serviceAddress: json['service_address'] != null
          ? AddressModel.fromJson(
              json['service_address'] as Map<String, dynamic>,
            )
          : null,
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
      createdAt: DateTime.parse(json['created_at'] as String),
      worker: json['worker'] != null
          ? WorkerModel.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
      serviceCategory: json['service_category'] != null
          ? ServiceCategoryModel.fromJson(
              json['service_category'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_number': bookingNumber,
      'customer_id': customerId,
      'worker_id': workerId,
      'service_category_id': serviceCategoryId,
      'status': status,
      'slot_date': slotDate.toIso8601String(),
      'slot_start': slotStart,
      'slot_end': slotEnd,
      'quoted_price': quotedPrice,
      'final_price': finalPrice,
      'booking_fee': bookingFee,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'service_address': serviceAddress?.toJson(),
      'customer_notes': customerNotes,
      'worker_notes': workerNotes,
      'checkin_otp': checkinOtp,
      'checkin_at': checkinAt?.toIso8601String(),
      'checkout_at': checkoutAt?.toIso8601String(),
      'cancelled_by': cancelledBy,
      'cancel_reason': cancelReason,
      'dispute_reason': disputeReason,
      'created_at': createdAt.toIso8601String(),
      'worker': worker?.toJson(),
      'service_category': serviceCategory?.toJson(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? bookingNumber,
    String? customerId,
    String? workerId,
    String? serviceCategoryId,
    String? status,
    DateTime? slotDate,
    String? slotStart,
    String? slotEnd,
    double? quotedPrice,
    double? finalPrice,
    double? bookingFee,
    String? paymentMethod,
    String? paymentStatus,
    AddressModel? serviceAddress,
    String? customerNotes,
    String? workerNotes,
    String? checkinOtp,
    DateTime? checkinAt,
    DateTime? checkoutAt,
    String? cancelledBy,
    String? cancelReason,
    String? disputeReason,
    DateTime? createdAt,
    WorkerModel? worker,
    ServiceCategoryModel? serviceCategory,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      serviceCategoryId: serviceCategoryId ?? this.serviceCategoryId,
      status: status ?? this.status,
      slotDate: slotDate ?? this.slotDate,
      slotStart: slotStart ?? this.slotStart,
      slotEnd: slotEnd ?? this.slotEnd,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      bookingFee: bookingFee ?? this.bookingFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      customerNotes: customerNotes ?? this.customerNotes,
      workerNotes: workerNotes ?? this.workerNotes,
      checkinOtp: checkinOtp ?? this.checkinOtp,
      checkinAt: checkinAt ?? this.checkinAt,
      checkoutAt: checkoutAt ?? this.checkoutAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: createdAt ?? this.createdAt,
      worker: worker ?? this.worker,
      serviceCategory: serviceCategory ?? this.serviceCategory,
    );
  }
}
