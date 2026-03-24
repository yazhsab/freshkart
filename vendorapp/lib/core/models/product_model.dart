class ProductModel {
  final String id;
  final String vendorId;
  final String categoryId;
  final String name;
  final String? nameTamil;
  final String? description;
  final String? imageUrl;
  final double price;
  final double? mrp;
  final String unit;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool isAvailable;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    this.nameTamil,
    this.description,
    this.imageUrl,
    required this.price,
    this.mrp,
    required this.unit,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.isAvailable = true,
    required this.createdAt,
  });

  /// Discount percentage if MRP is set and greater than price
  double get discountPercentage {
    if (mrp != null && mrp! > price) {
      return ((mrp! - price) / mrp! * 100);
    }
    return 0.0;
  }

  /// Whether the product has stock available
  bool get isInStock => stockQuantity > 0;

  /// Whether the product stock is below the low stock threshold
  bool get isLowStock =>
      stockQuantity > 0 && stockQuantity <= lowStockThreshold;

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
      mrp: (json['mrp'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '1 kg',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 5,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'low_stock_threshold': lowStockThreshold,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
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
    int? lowStockThreshold,
    bool? isAvailable,
    DateTime? createdAt,
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
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
