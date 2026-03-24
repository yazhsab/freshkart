class ServiceCategoryModel {
  final String id;
  final String name;
  final String? nameTamil;
  final String? iconUrl;
  final String? description;
  final double basePrice;
  final String priceType;
  final int estimatedDurationMins;
  final bool isActive;
  final int sortOrder;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    this.nameTamil,
    this.iconUrl,
    this.description,
    required this.basePrice,
    required this.priceType,
    required this.estimatedDurationMins,
    required this.isActive,
    required this.sortOrder,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameTamil: json['name_tamil'] as String?,
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      priceType: json['price_type'] as String,
      estimatedDurationMins: json['estimated_duration_mins'] as int,
      isActive: json['is_active'] as bool,
      sortOrder: json['sort_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
  }

  ServiceCategoryModel copyWith({
    String? id,
    String? name,
    String? nameTamil,
    String? iconUrl,
    String? description,
    double? basePrice,
    String? priceType,
    int? estimatedDurationMins,
    bool? isActive,
    int? sortOrder,
  }) {
    return ServiceCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameTamil: nameTamil ?? this.nameTamil,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      priceType: priceType ?? this.priceType,
      estimatedDurationMins:
          estimatedDurationMins ?? this.estimatedDurationMins,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
