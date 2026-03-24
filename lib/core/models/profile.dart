class Profile {
  final String id;
  final String? fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  Profile({
    required this.id,
    this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'avatar_url': avatarUrl,
        'role': role,
        'is_active': isActive,
      };

  String get displayName => fullName?.isNotEmpty == true ? fullName! : phone;

  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
