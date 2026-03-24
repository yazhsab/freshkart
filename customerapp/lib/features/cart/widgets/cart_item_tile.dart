import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/models/cart_item_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';

class CartItemTile extends ConsumerWidget {
  final CartItemModel item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(cartProvider.notifier).removeItem(item.product.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Product thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.product.imageUrl != null
                  ? Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          size: 28,
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        size: 28,
                        color: AppColors.textHint,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Name + unit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.product.unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Quantity stepper
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGreen),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.product.id, item.quantity - 1),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (item.quantity < AppConfig.maxCartItemsPerProduct) {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.product.id, item.quantity + 1);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Price
            Text(
              '${AppConfig.currencySymbol}${item.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
