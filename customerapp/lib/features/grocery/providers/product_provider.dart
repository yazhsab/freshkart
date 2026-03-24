import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/product_model.dart';

final productDetailProvider = FutureProvider.family<ProductModel, String>((
  ref,
  productId,
) async {
  final api = ApiClient();
  final response = await api.get(ApiEndpoints.productById(productId));
  return ProductModel.fromJson(response.data as Map<String, dynamic>);
});
