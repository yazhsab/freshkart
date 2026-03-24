class AgentModel {
  final String id;
  final String profileId;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String vehicleType;
  final String vehicleNumber;
  final String? vehicleDocUrl;
  final String aadhaarNumber;
  final String? aadhaarDocUrl;
  final bool isOnline;
  final bool isApproved;
  final double rating;
  final int totalRatings;
  final int totalDeliveries;
  final DateTime joinedAt;

  const AgentModel({
    required this.id,
    required this.profileId,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    required this.vehicleType,
    required this.vehicleNumber,
    this.vehicleDocUrl,
    required this.aadhaarNumber,
    this.aadhaarDocUrl,
    this.isOnline = false,
    this.isApproved = false,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalDeliveries = 0,
    required this.joinedAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatar_url'] as String?,
      vehicleType: json['vehicle_type'] as String,
      vehicleNumber: json['vehicle_number'] as String,
      vehicleDocUrl: json['vehicle_doc_url'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String,
      aadhaarDocUrl: json['aadhaar_doc_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'vehicle_doc_url': vehicleDocUrl,
      'aadhaar_number': aadhaarNumber,
      'aadhaar_doc_url': aadhaarDocUrl,
      'is_online': isOnline,
      'is_approved': isApproved,
      'rating': rating,
      'total_ratings': totalRatings,
      'total_deliveries': totalDeliveries,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  AgentModel copyWith({
    String? id,
    String? profileId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? vehicleType,
    String? vehicleNumber,
    String? vehicleDocUrl,
    String? aadhaarNumber,
    String? aadhaarDocUrl,
    bool? isOnline,
    bool? isApproved,
    double? rating,
    int? totalRatings,
    int? totalDeliveries,
    DateTime? joinedAt,
  }) {
    return AgentModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleDocUrl: vehicleDocUrl ?? this.vehicleDocUrl,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarDocUrl: aadhaarDocUrl ?? this.aadhaarDocUrl,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  String get ratingDisplay => rating.toStringAsFixed(1);

  String get vehicleDisplay => vehicleType
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      })
      .join(' ');
}
