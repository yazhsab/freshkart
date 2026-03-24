import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/models/product_model.dart';
import 'package:freshkart_customer/core/models/category_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/features/grocery/providers/vendor_provider.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));
    final cartState = ref.watch(cartProvider);

    return vendorAsync.when(
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
                'Failed to load vendor details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(vendorDetailProvider(widget.vendorId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (detail) {
        // Initialize tab controller when data arrives
        if (!mounted) return const SizedBox.shrink();
        _tabController = TabController(
          length: detail.categories.length,
          vsync: this,
          initialIndex: _selectedCategoryIndex,
        );
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            setState(() {
              _selectedCategoryIndex = _tabController.index;
            });
          }
        });

        final vendor = detail.vendor;
        final hasCartItems =
            cartState.vendorId == widget.vendorId && cartState.items.isNotEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // SliverAppBar with vendor banner
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryGreen,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    vendor.shopName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.darkGreen, AppColors.primaryGreen],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 60, 16, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (vendor.shopNameTamil != null)
                              Text(
                                vendor.shopNameTamil!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${vendor.rating.toStringAsFixed(1)} (${vendor.totalRatings})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  vendor.isOpen
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  color: vendor.isOpen
                                      ? Colors.greenAccent
                                      : Colors.red,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  vendor.isOpen ? 'Open' : 'Closed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                if (vendor.estimatedDeliveryMins != null) ...[
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vendor.estimatedDeliveryMins} min',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Category tabs
              if (detail.categories.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryTabDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primaryGreen,
                      indicatorWeight: 3,
                      tabAlignment: TabAlignment.start,
                      tabs: detail.categories
                          .map((cat) => Tab(text: cat.name))
                          .toList(),
                    ),
                  ),
                ),

              // Product sections per category
              ...detail.categories.map((category) {
                final products = detail.productsByCategory[category.id] ?? [];
                return SliverMainAxisGroup(
                  slivers: [
                    // Sticky category header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SectionHeaderDelegate(
                        category: category,
                        itemCount: products.length,
                      ),
                    ),
                    // 2-column grid of products
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProductCard(
                            product: products[index],
                            onTap: () =>
                                context.push('/products/${products[index].id}'),
                          ),
                          childCount: products.length,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Bottom padding for floating bar
              if (hasCartItems)
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),

          // Floating bottom cart bar
          bottomNavigationBar: hasCartItems
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Text(
                          '${cartState.itemCount} items | ${AppConfig.currencySymbol}${cartState.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => context.push('/cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Cart',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// --- Delegate for category tabs ---
class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _CategoryTabDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_CategoryTabDelegate oldDelegate) => false;
}

// --- Delegate for sticky section headers ---
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final CategoryModel category;
  final int itemCount;

  _SectionHeaderDelegate({required this.category, required this.itemCount});

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (category.nameTamil != null) ...[
            const SizedBox(width: 8),
            Text(
              category.nameTamil!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const Spacer(),
          Text(
            '$itemCount items',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SectionHeaderDelegate oldDelegate) =>
      category.id != oldDelegate.category.id;
}

// --- Product card widget ---
class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

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
            // Product image
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

            // Product info
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
                          _MiniQuantityStepper(
                            quantity: cartItem.quantity,
                            onIncrement: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  product.id,
                                  cartItem.quantity + 1,
                                ),
                            onDecrement: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  product.id,
                                  cartItem.quantity - 1,
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

class _MiniQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MiniQuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryGreen),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.remove,
                size: 14,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.add, size: 14, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
