import 'package:flutter/material.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/models/product_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/network_image_widget.dart';
import 'package:freshkart_vendor/features/inventory/widgets/stock_badge.dart';

class ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final ValueChanged<int>? onStockUpdate;
  final ValueChanged<bool>? onToggleAvailability;
  final VoidCallback? onDelete;

  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.onStockUpdate,
    this.onToggleAvailability,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(product.id),
      background: _buildSwipeBackground(
        color: VendorColors.primary,
        icon: Icons.inventory_2_rounded,
        label: 'Update Stock',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: VendorColors.error,
        icon: Icons.delete_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showQuickStockSheet(context);
          return false;
        } else {
          return await _confirmDelete(context);
        }
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VendorColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VendorColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              // Product image
              _buildImage(),
              const SizedBox(width: 12),

              // Center info
              Expanded(child: _buildInfo()),

              // Right side: stock badge + availability
              _buildRightColumn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return NetworkImageWidget(
        url: product.imageUrl!,
        width: 56,
        height: 56,
        radius: 8,
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: VendorColors.fieldBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_rounded,
        color: VendorColors.disabled,
        size: 28,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        Text(
          product.unit,
          style: const TextStyle(
            fontSize: 12,
            color: VendorColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              CurrencyUtil.formatPrice(product.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: VendorColors.inStock,
              ),
            ),
            if (product.mrp != null && product.mrp! > product.price) ...[
              const SizedBox(width: 6),
              Text(
                CurrencyUtil.formatPrice(product.mrp!),
                style: const TextStyle(
                  fontSize: 12,
                  color: VendorColors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        StockBadge(
          quantity: product.stockQuantity,
          lowStockThreshold: product.lowStockThreshold,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 24,
          child: Transform.scale(
            scale: 0.7,
            child: Switch.adaptive(
              value: product.isAvailable,
              onChanged: onToggleAvailability,
              activeColor: VendorColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickStockSheet(BuildContext context) {
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Stock: ${product.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current stock: ${product.stockQuantity}',
                style: const TextStyle(
                  fontSize: 13,
                  color: VendorColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _quickStockButton(
                    ctx,
                    label: '+10',
                    qty: product.stockQuantity + 10,
                  ),
                  const SizedBox(width: 12),
                  _quickStockButton(
                    ctx,
                    label: '+50',
                    qty: product.stockQuantity + 50,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Custom qty',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: VendorColors.primary,
                          ),
                          onPressed: () {
                            final val = int.tryParse(customController.text);
                            if (val != null && val >= 0 && val <= 9999) {
                              onStockUpdate?.call(val);
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickStockButton(
    BuildContext context, {
    required String label,
    required int qty,
  }) {
    return ElevatedButton(
      onPressed: () {
        onStockUpdate?.call(qty.clamp(0, 9999));
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: VendorColors.primaryBg,
        foregroundColor: VendorColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Product',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VendorColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: const TextStyle(
            fontSize: 15,
            color: VendorColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: VendorColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: VendorColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      onDelete?.call();
    }
    return false; // Don't dismiss the Dismissible itself
  }
}
