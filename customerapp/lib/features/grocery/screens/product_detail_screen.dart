import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/grocery/providers/product_provider.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final cartState = ref.watch(cartProvider);

    return productAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load product',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(widget.productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (product) {
        final existingCartItem = cartState.items[product.id];
        final qty = existingCartItem?.quantity ?? _quantity;
        final totalPrice = product.price * qty;

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero image area
                      Container(
                        height: 280,
                        width: double.infinity,
                        color: AppColors.background,
                        child: Stack(
                          children: [
                            Center(
                              child: product.imageUrl != null
                                  ? Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 280,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.shopping_basket_outlined,
                                        size: 80,
                                        color: AppColors.textHint,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_basket_outlined,
                                      size: 80,
                                      color: AppColors.textHint,
                                    ),
                            ),
                            // Back button
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 8,
                              left: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.textPrimary,
                                  ),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                            ),
                            // Discount badge
                            if (product.discountPercentage > 0)
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 8,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${product.discountPercentage}% OFF',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // White card body
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            // Tamil name
                            if (product.nameTamil != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                product.nameTamil!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Price row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${AppConfig.currencySymbol}${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                if (product.discountPercentage > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${AppConfig.currencySymbol}${product.mrp.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textHint,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${product.discountPercentage}% OFF',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Unit info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.unit,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Vendor row
                            InkWell(
                              onTap: () =>
                                  context.push('/vendors/${product.vendorId}'),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.backgroundGreen,
                                    child: Icon(
                                      Icons.store,
                                      size: 20,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'View Vendor Store',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textHint,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Description (expandable)
                            if (product.description != null &&
                                product.description!.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _descriptionExpanded =
                                        !_descriptionExpanded;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          _descriptionExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: AppColors.textHint,
                                        ),
                                      ],
                                    ),
                                    if (_descriptionExpanded) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        product.description!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                            ],

                            // Ratings section
                            const Text(
                              'Ratings & Reviews',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (index) => const Icon(
                                    Icons.star_border,
                                    color: AppColors.textHint,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky bottom bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity stepper
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                if (existingCartItem != null) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(product.id, qty - 1);
                                } else if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                if (existingCartItem != null) {
                                  if (qty < AppConfig.maxCartItemsPerProduct) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(product.id, qty + 1);
                                  }
                                } else if (_quantity <
                                    AppConfig.maxCartItemsPerProduct) {
                                  setState(() => _quantity++);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Add to cart button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: product.isInStock
                                ? () {
                                    if (existingCartItem == null) {
                                      ref
                                          .read(cartProvider.notifier)
                                          .addItem(product, qty: _quantity);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Added to cart'),
                                          duration: Duration(seconds: 1),
                                          backgroundColor:
                                              AppColors.primaryGreen,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.divider,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              existingCartItem != null
                                  ? 'In Cart - ${AppConfig.currencySymbol}${totalPrice.toStringAsFixed(0)}'
                                  : product.isInStock
                                  ? 'Add to Cart ${AppConfig.currencySymbol}${totalPrice.toStringAsFixed(0)}'
                                  : 'Out of Stock',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
