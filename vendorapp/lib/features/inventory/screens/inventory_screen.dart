import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/features/shared/widgets/vendor_bottom_nav.dart';
import 'package:freshkart_vendor/features/shared/widgets/empty_state_widget.dart';
import 'package:freshkart_vendor/features/inventory/providers/inventory_provider.dart';
import 'package:freshkart_vendor/features/inventory/widgets/product_tile.dart';
import 'package:freshkart_vendor/features/inventory/widgets/category_filter.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String? _activeStatFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorId = SupabaseConfig.currentUser?.id;
      if (vendorId != null) {
        ref.read(inventoryProvider.notifier).fetchProducts(vendorId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: Text(
          'Inventory (${state.totalCount} products)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VendorColors.textPrimary,
          ),
        ),
        backgroundColor: VendorColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.sort_rounded,
              color: VendorColors.textPrimary,
            ),
            onPressed: () => _showSortSheet(context),
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(
              Icons.grid_view_rounded,
              color: VendorColors.textPrimary,
            ),
            onPressed: () => context.push('/inventory/bulk-update'),
            tooltip: 'Bulk Update',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VendorColors.primary),
            )
          : RefreshIndicator(
              color: VendorColors.primary,
              onRefresh: () async {
                final vendorId = SupabaseConfig.currentUser?.id;
                if (vendorId != null) {
                  await ref
                      .read(inventoryProvider.notifier)
                      .fetchProducts(vendorId);
                }
              },
              child: CustomScrollView(
                slivers: [
                  // Summary stats row
                  SliverToBoxAdapter(child: _buildSummaryRow(state)),

                  // Low stock alert banner
                  if (state.lowStockCount > 0)
                    SliverToBoxAdapter(child: _buildLowStockBanner(state)),

                  // Search bar
                  SliverToBoxAdapter(child: _buildSearchBar()),

                  // Category filter chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: categories.when(
                        data: (cats) => CategoryFilter(
                          categories: cats,
                          selectedId: state.selectedCategoryId,
                          onSelected: (id) {
                            ref
                                .read(inventoryProvider.notifier)
                                .filterByCategory(id);
                          },
                        ),
                        loading: () => const SizedBox(height: 40),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Error banner
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VendorColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                            color: VendorColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                  // Product list
                  if (state.filteredProducts.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products found',
                        subtitle: state.searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Add your first product to get started',
                        actionLabel: state.searchQuery.isEmpty
                            ? 'Add Product'
                            : null,
                        onAction: state.searchQuery.isEmpty
                            ? () => context.push('/inventory/add')
                            : null,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: state.filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = state.filteredProducts[index];
                          return ProductTile(
                            product: product,
                            onTap: () =>
                                context.push('/inventory/${product.id}/edit'),
                            onStockUpdate: (qty) {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .updateStock(product.id, qty);
                            },
                            onToggleAvailability: (val) {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .toggleAvailability(product.id, val);
                            },
                            onDelete: () {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .deleteProduct(product.id);
                            },
                          );
                        },
                      ),
                    ),

                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/add'),
        backgroundColor: VendorColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: VendorBottomNav(
        currentIndex: 2,
        lowStockCount: state.lowStockCount,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/orders');
              break;
            case 2:
              break; // Already on inventory
            case 3:
              context.go('/shop');
              break;
          }
        },
      ),
    );
  }

  Widget _buildSummaryRow(InventoryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildStatCard(
            label: 'Total',
            count: state.totalCount,
            color: VendorColors.textPrimary,
            filterKey: null,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            label: 'Available',
            count: state.availableCount,
            color: VendorColors.inStock,
            filterKey: 'available',
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            label: 'Low Stock',
            count: state.lowStockCount,
            color: VendorColors.lowStock,
            filterKey: 'low_stock',
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            label: 'Out of Stock',
            count: state.outOfStockCount,
            color: VendorColors.outOfStock,
            filterKey: 'out_of_stock',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required String? filterKey,
  }) {
    final isActive = _activeStatFilter == filterKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeStatFilter = isActive ? null : filterKey;
          });
          ref
              .read(inventoryProvider.notifier)
              .filterByStockStatus(isActive ? null : filterKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : VendorColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : VendorColors.divider,
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: VendorColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockBanner(InventoryState state) {
    return GestureDetector(
      onTap: () => context.push('/inventory/low-stock'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: VendorColors.lowStock.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: VendorColors.lowStock.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: VendorColors.lowStock,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${state.lowStockCount} products running low! Update stock',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.lowStock,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: VendorColors.lowStock,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          ref.read(inventoryProvider.notifier).search(query);
        },
        style: const TextStyle(fontSize: 14, color: VendorColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(
            color: VendorColors.textHint,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: VendorColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: VendorColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(inventoryProvider.notifier).search('');
                  },
                )
              : null,
          filled: true,
          fillColor: VendorColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: VendorColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VendorColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: VendorColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final currentSort = ref.read(inventoryProvider).sortBy;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: VendorColors.textPrimary,
                  ),
                ),
              ),
              _sortOption(
                ctx,
                label: 'Name',
                value: 'name',
                current: currentSort,
              ),
              _sortOption(
                ctx,
                label: 'Stock',
                value: 'stock',
                current: currentSort,
              ),
              _sortOption(
                ctx,
                label: 'Price',
                value: 'price',
                current: currentSort,
              ),
              _sortOption(
                ctx,
                label: 'Sales',
                value: 'sales',
                current: currentSort,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortOption(
    BuildContext context, {
    required String label,
    required String value,
    required String current,
  }) {
    final isSelected = current == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? VendorColors.primary : VendorColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: VendorColors.textPrimary,
        ),
      ),
      onTap: () {
        ref.read(inventoryProvider.notifier).sortProducts(value);
        Navigator.pop(context);
      },
    );
  }
}
