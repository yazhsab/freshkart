class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImageUrl: json['product_image_url'] as String?,
      unit: json['unit'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? unit,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
