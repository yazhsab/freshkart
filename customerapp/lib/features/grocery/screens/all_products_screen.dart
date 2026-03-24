import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/models/product_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';

/// Provider that fetches products by vendorId and/or categoryId.
final allProductsProvider =
    FutureProvider.family<
      List<ProductModel>,
      ({String? vendorId, String? categoryId})
    >((ref, params) async {
      final api = ApiClient();

      if (params.vendorId != null) {
        final response = await api.get(
          ApiEndpoints.vendorProducts(params.vendorId!),
        );
        final products = (response.data as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (params.categoryId != null) {
          return products
              .where((p) => p.categoryId == params.categoryId)
              .toList();
        }
        return products;
      }

      // Search by category if no vendorId
      final queryParams = <String, dynamic>{};
      if (params.categoryId != null) {
        queryParams['category_id'] = params.categoryId;
      }
      final response = await api.get(
        ApiEndpoints.searchProducts,
        queryParameters: queryParams,
      );
      return (response.data as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });

class AllProductsScreen extends ConsumerWidget {
  final String? vendorId;
  final String? categoryId;

  const AllProductsScreen({super.key, this.vendorId, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (vendorId: vendorId, categoryId: categoryId);
    final productsAsync = ref.watch(allProductsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      backgroundColor: AppColors.background,
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load products',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allProductsProvider(params)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try a different category or vendor',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _AllProductCard(
                product: product,
                onTap: () => context.push('/products/${product.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _AllProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _AllProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartItem = cartState.items[product.id];
    final inCart = cartItem != null;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: AppColors.background,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: AppColors.textHint,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          size: 40,
                          color: AppColors.textHint,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${AppConfig.currencySymbol}${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${AppConfig.currencySymbol}${product.mrp.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (!product.isInStock)
                          const Text(
                            'Out of stock',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else if (inCart)
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryGreen),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                        product.id,
                                        cartItem.quantity - 1,
                                      ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                        product.id,
                                        cartItem.quantity + 1,
                                      ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .addItem(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
