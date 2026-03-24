class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String? comment;
  final String? serviceName;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    this.comment,
    this.serviceName,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? 'Customer',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      serviceName: json['service_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
