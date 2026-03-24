class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final String? productImageUrl;
  final String? unit;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    this.productImageUrl,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      productImageUrl: json['product_image_url'] as String?,
      unit: json['unit'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'product_image_url': productImageUrl,
        'unit': unit,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };
}
