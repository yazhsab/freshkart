import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/vendor_model.dart';
import 'package:freshkart_customer/core/models/product_model.dart';
import 'package:freshkart_customer/core/models/category_model.dart';

class VendorDetail {
  final VendorModel vendor;
  final Map<String, List<ProductModel>> productsByCategory;
  final List<CategoryModel> categories;

  const VendorDetail({
    required this.vendor,
    required this.productsByCategory,
    required this.categories,
  });
}

final vendorDetailProvider = FutureProvider.family<VendorDetail, String>((
  ref,
  vendorId,
) async {
  final api = ApiClient();

  // Fetch vendor info and products in parallel
  final results = await Future.wait([
    api.get(ApiEndpoints.vendorById(vendorId)),
    api.get(ApiEndpoints.vendorProducts(vendorId)),
  ]);

  final vendorJson = results[0].data as Map<String, dynamic>;
  final vendor = VendorModel.fromJson(vendorJson);

  final productsJson = results[1].data as List<dynamic>;
  final products = productsJson
      .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
      .toList();

  // Group products by categoryId
  final Map<String, List<ProductModel>> productsByCategory = {};
  for (final product in products) {
    productsByCategory.putIfAbsent(product.categoryId, () => []).add(product);
  }

  // Build category list from grouped keys
  // Fetch categories to get proper names
  final categoriesResponse = await api.get(ApiEndpoints.groceryCategories);
  final allCategories = (categoriesResponse.data as List<dynamic>)
      .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();

  // Filter to only categories that have products from this vendor
  final categories =
      allCategories
          .where((cat) => productsByCategory.containsKey(cat.id))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return VendorDetail(
    vendor: vendor,
    productsByCategory: productsByCategory,
    categories: categories,
  );
});
