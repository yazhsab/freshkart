class CategoryModel {
  final String id;
  final String name;
  final String? nameTamil;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.nameTamil,
    this.iconUrl,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameTamil: json['name_tamil'] as String?,
      iconUrl: json['icon_url'] as String?,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_tamil': nameTamil,
      'icon_url': iconUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? nameTamil,
    String? iconUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameTamil: nameTamil ?? this.nameTamil,
      iconUrl: iconUrl ?? this.iconUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
