import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../../shared/widgets/network_image_widget.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final quantity = cartState.quantityOf(product.id);
    final inCart = quantity > 0;
    final discount = product.discountPercentage;
    final savings = (product.mrp - product.price).clamp(0, double.infinity);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.64),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: SizedBox(
                      height: 164,
                      width: double.infinity,
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                NetworkImageWidget(
                                  url: product.imageUrl,
                                  width: double.infinity,
                                  height: 164,
                                  radius: 0,
                                  fit: BoxFit.cover,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.12),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.2),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0, 0.45, 1],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: AppColors.surfaceAlt,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 44,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _PillLabel(
                      text: discount > 0 ? '$discount% OFF' : product.unit,
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primaryGreen.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _PillLabel(
                      text: product.isInStock ? 'In stock' : 'Sold out',
                      foregroundColor: product.isInStock
                          ? AppColors.primaryGreen
                          : AppColors.error,
                      backgroundColor: product.isInStock
                          ? Colors.white
                          : AppColors.error.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (discount > 0)
                            _InfoChip(
                              icon: Icons.bolt_rounded,
                              label: 'Save \u20B9${savings.toStringAsFixed(0)}',
                              color: AppColors.accentCoral,
                              backgroundColor: AppColors.spotlightPeach,
                            ),
                          _InfoChip(
                            icon: Icons.shopping_bag_outlined,
                            label: inCart
                                ? '$quantity in cart'
                                : 'Ready to add',
                            color: AppColors.primaryGreen,
                            backgroundColor: AppColors.backgroundGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\u20B9${product.price.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                if (discount > 0)
                                  Text(
                                    '\u20B9${product.mrp.toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!product.isInStock)
                            const _OutOfStockBadge()
                          else if (inCart)
                            _QuantityControls(
                              quantity: quantity,
                              onIncrement: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(product.id, quantity + 1);
                              },
                              onDecrement: () {
                                if (quantity <= 1) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .removeItem(product.id);
                                } else {
                                  ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(product.id, quantity - 1);
                                }
                              },
                            )
                          else
                            _AddButton(
                              onTap: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(product);
                              },
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
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityControls({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(Icons.remove_rounded, onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          _buildButton(Icons.add_rounded, onIncrement),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 92,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;

  const _PillLabel({
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutOfStockBadge extends StatelessWidget {
  const _OutOfStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
      ),
      child: const Text(
        'Sold out',
        style: TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
