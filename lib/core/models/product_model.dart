class ProductModel {
  final String id;
  final String vendorId;
  final String categoryId;
  final String name;
  final String? nameTamil;
  final String? description;
  final String? imageUrl;
  final double price;
  final double mrp;
  final String unit;
  final int stockQuantity;
  final bool isAvailable;

  const ProductModel({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    this.nameTamil,
    this.description,
    this.imageUrl,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.stockQuantity,
    required this.isAvailable,
  });

  int get discountPercentage =>
      mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;

  bool get isInStock => stockQuantity > 0 && isAvailable;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      nameTamil: json['name_tamil'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num).toDouble(),
      mrp: (json['mrp'] as num).toDouble(),
      unit: json['unit'] as String,
      stockQuantity: json['stock_quantity'] as int,
      isAvailable: json['is_available'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'category_id': categoryId,
      'name': name,
      'name_tamil': nameTamil,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
    };
  }

  ProductModel copyWith({
    String? id,
    String? vendorId,
    String? categoryId,
    String? name,
    String? nameTamil,
    String? description,
    String? imageUrl,
    double? price,
    double? mrp,
    String? unit,
    int? stockQuantity,
    bool? isAvailable,
  }) {
    return ProductModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      nameTamil: nameTamil ?? this.nameTamil,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
