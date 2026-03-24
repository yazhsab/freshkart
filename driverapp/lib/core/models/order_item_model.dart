class OrderItemModel {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String unit;
  final String? imageUrl;

  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.unit,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final price = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
    return OrderItemModel(
      id: json['id'] as String,
      productName: json['product_name'] as String? ?? '',
      quantity: qty,
      unitPrice: price,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? (qty * price),
      unit: json['unit'] as String? ?? 'pcs',
      imageUrl: json['image_url'] as String?,
    );
  }

  String get displayQuantity => '$quantity $unit';

  String get displayLine => '$productName x$quantity';
}
