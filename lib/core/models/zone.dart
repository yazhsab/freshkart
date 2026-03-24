class Zone {
  final String id;
  final String name;
  final String city;
  final String state;
  final List<String> pincodes;
  final String? zoneType;
  final double? deliveryFeeOverride;
  final bool isActive;
  final DateTime? createdAt;

  Zone({
    required this.id,
    required this.name,
    required this.city,
    this.state = 'Tamil Nadu',
    this.pincodes = const [],
    this.zoneType,
    this.deliveryFeeOverride,
    this.isActive = true,
    this.createdAt,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? 'Tamil Nadu',
      pincodes: (json['pincodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      zoneType: json['zone_type'] as String?,
      deliveryFeeOverride:
          (json['delivery_fee_override'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'city': city,
        'state': state,
        'pincodes': pincodes,
        'zone_type': zoneType,
        'delivery_fee_override': deliveryFeeOverride,
        'is_active': isActive,
      };
}
