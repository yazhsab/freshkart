import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String vendorId;

  const CartItemModel({
    required this.product,
    required this.quantity,
    required this.vendorId,
  });

  double get totalPrice => product.price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      vendorId: json['vendor_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'vendor_id': vendorId,
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? vendorId,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}
