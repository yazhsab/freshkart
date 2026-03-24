import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/models/product_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/network_image_widget.dart';
import 'package:freshkart_vendor/features/inventory/providers/inventory_provider.dart';
import 'package:freshkart_vendor/features/inventory/widgets/stock_badge.dart';

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  // Map of productId -> new stock quantity
  final Map<String, int> _stockUpdates = {};
  // Set of productIds to mark as unavailable
  final Set<String> _markUnavailable = {};
  bool _isSaving = false;

  List<ProductModel> _getLowStockProducts(InventoryState state) {
    return state.products
        .where(
          (p) => p.stockQuantity <= p.lowStockThreshold || p.stockQuantity == 0,
        )
        .toList();
  }

  int _getCurrentStock(ProductModel product) {
    return _stockUpdates[product.id] ?? product.stockQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final lowStockProducts = _getLowStockProducts(state);

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: const Text(
          'Low Stock Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VendorColors.textPrimary,
          ),
        ),
        backgroundColor: VendorColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: VendorColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: lowStockProducts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: VendorColors.inStock,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All products are well stocked!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lowStockProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = lowStockProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final currentStock = _getCurrentStock(product);
    final isMarkedUnavailable = _markUnavailable.contains(product.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _stockUpdates.containsKey(product.id)
              ? VendorColors.primary.withValues(alpha: 0.4)
              : VendorColors.divider,
          width: _stockUpdates.containsKey(product.id) ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Image
              if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                NetworkImageWidget(
                  url: product.imageUrl!,
                  width: 48,
                  height: 48,
                  radius: 8,
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: VendorColors.fieldBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_rounded,
                    color: VendorColors.disabled,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 12),

              // Name and stock info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StockBadge(
                          quantity: currentStock,
                          lowStockThreshold: product.lowStockThreshold,
                        ),
                        if (_stockUpdates.containsKey(product.id)) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(was ${product.stockQuantity})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: VendorColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick add buttons
          Row(
            children: [
              _quickAddButton(product, 10),
              const SizedBox(width: 8),
              _quickAddButton(product, 50),
              const SizedBox(width: 8),
              _quickAddButton(product, 100),
              const SizedBox(width: 8),
              _customButton(product),
            ],
          ),

          // Mark unavailable if out of stock
          if (product.stockQuantity == 0 &&
              !_stockUpdates.containsKey(product.id))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: isMarkedUnavailable,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _markUnavailable.add(product.id);
                          } else {
                            _markUnavailable.remove(product.id);
                          }
                        });
                      },
                      activeColor: VendorColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mark unavailable',
                    style: TextStyle(
                      fontSize: 13,
                      color: VendorColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickAddButton(ProductModel product, int amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          final current = _getCurrentStock(product);
          setState(() {
            _stockUpdates[product.id] = (current + amount).clamp(0, 9999);
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: VendorColors.primary,
          side: const BorderSide(color: VendorColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '+$amount',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _customButton(ProductModel product) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _showCustomInput(product),
        style: OutlinedButton.styleFrom(
          foregroundColor: VendorColors.textSecondary,
          side: const BorderSide(color: VendorColors.divider),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Custom',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showCustomInput(ProductModel product) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Set Stock Quantity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter new quantity',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: VendorColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0 && val <= 9999) {
                setState(() {
                  _stockUpdates[product.id] = val;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Set',
              style: TextStyle(
                color: VendorColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasChanges = _stockUpdates.isNotEmpty || _markUnavailable.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: VendorColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        label: hasChanges
            ? 'Update All (${_stockUpdates.length + _markUnavailable.length} changes)'
            : 'No changes',
        isLoading: _isSaving,
        onPressed: hasChanges ? _saveAll : null,
        icon: Icons.save_rounded,
      ),
    );
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    final notifier = ref.read(inventoryProvider.notifier);

    try {
      // Update stock quantities
      for (final entry in _stockUpdates.entries) {
        await notifier.updateStock(entry.key, entry.value);
      }

      // Mark unavailable
      for (final productId in _markUnavailable) {
        await notifier.toggleAvailability(productId, false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: VendorColors.inStock,
          ),
        );
        setState(() {
          _stockUpdates.clear();
          _markUnavailable.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: VendorColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
