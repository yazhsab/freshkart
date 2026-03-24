class ReviewModel {
  final String id;
  final String reviewerId;
  final String? targetId;
  final String targetType;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    this.targetId,
    required this.targetType,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String,
      targetId: json['target_id'] as String?,
      targetType: json['target_type'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      'target_id': targetId,
      'target_type': targetType,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? targetId,
    String? targetType,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
