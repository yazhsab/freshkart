class Product {
  final String id;
  final String vendorId;
  final String? categoryId;
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
  final int sortOrder;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.vendorId,
    this.categoryId,
    required this.name,
    this.nameTamil,
    this.description,
    this.imageUrl,
    required this.price,
    this.mrp,
    this.unit = '1 kg',
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String? ?? '',
      nameTamil: json['name_tamil'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '1 kg',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 5,
      isAvailable: json['is_available'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
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
        'sort_order': sortOrder,
      };

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  double? get discountPercent {
    if (mrp == null || mrp! <= price) return null;
    return ((mrp! - price) / mrp! * 100);
  }
}
