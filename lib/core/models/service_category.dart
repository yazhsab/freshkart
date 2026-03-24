class ServiceCategory {
  final String id;
  final String name;
  final String? nameTamil;
  final String? iconUrl;
  final String? description;
  final double? basePrice;
  final String priceType;
  final int estimatedDurationMins;
  final bool isActive;
  final int sortOrder;

  ServiceCategory({
    required this.id,
    required this.name,
    this.nameTamil,
    this.iconUrl,
    this.description,
    this.basePrice,
    this.priceType = 'fixed',
    this.estimatedDurationMins = 60,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nameTamil: json['name_tamil'] as String?,
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String?,
      basePrice: (json['base_price'] as num?)?.toDouble(),
      priceType: json['price_type'] as String? ?? 'fixed',
      estimatedDurationMins:
          json['estimated_duration_mins'] as int? ?? 60,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_tamil': nameTamil,
        'icon_url': iconUrl,
        'description': description,
        'base_price': basePrice,
        'price_type': priceType,
        'estimated_duration_mins': estimatedDurationMins,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  String get durationLabel {
    if (estimatedDurationMins >= 60) {
      final h = estimatedDurationMins ~/ 60;
      final m = estimatedDurationMins % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${estimatedDurationMins}m';
  }

  String get priceLabel {
    if (priceType == 'on_inspection') return 'On inspection';
    if (priceType == 'variable') return 'From \u20B9${basePrice?.toStringAsFixed(0) ?? '0'}';
    return '\u20B9${basePrice?.toStringAsFixed(0) ?? '0'}';
  }
}
