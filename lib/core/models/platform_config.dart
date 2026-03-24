class PlatformConfig {
  final String key;
  final String value;
  final String? description;
  final DateTime? updatedAt;

  PlatformConfig({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'description': description,
      };
}
