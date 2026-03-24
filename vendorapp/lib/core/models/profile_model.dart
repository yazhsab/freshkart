class ProfileModel {
  final String id;
  final String? fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
