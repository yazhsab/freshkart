class Review {
  final String id;
  final String refType;
  final String refId;
  final String? customerId;
  final String? orderOrBookingId;
  final int rating;
  final String? comment;
  final bool isVisible;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.refType,
    required this.refId,
    this.customerId,
    this.orderOrBookingId,
    required this.rating,
    this.comment,
    this.isVisible = true,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      refType: json['ref_type'] as String,
      refId: json['ref_id'] as String,
      customerId: json['customer_id'] as String?,
      orderOrBookingId: json['order_or_booking_id'] as String?,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ref_type': refType,
        'ref_id': refId,
        'customer_id': customerId,
        'order_or_booking_id': orderOrBookingId,
        'rating': rating,
        'comment': comment,
        'is_visible': isVisible,
      };
}
