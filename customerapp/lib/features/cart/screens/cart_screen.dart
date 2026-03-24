import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';
import 'package:freshkart_customer/features/cart/providers/address_provider.dart';
import 'package:freshkart_customer/features/cart/widgets/cart_item_tile.dart';
import 'package:freshkart_customer/features/cart/widgets/price_summary_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                      'Are you sure you want to remove all items?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: cartState.items.isEmpty
          ? _buildEmptyState(context)
          : _buildCartContent(context, cartState, selectedAddress),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items from a vendor to get started',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start Shopping',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    CartState cartState,
    selectedAddress,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Vendor info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.backgroundGreen,
                      child: Icon(
                        Icons.store,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartState.vendorName ?? 'Vendor',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${cartState.itemCount} items',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cart items
              ...cartState.itemsList.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CartItemTile(item: item),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery address card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: InkWell(
                  onTap: () => context.push('/addresses'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: selectedAddress != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundGreen,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          selectedAddress.label,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Deliver to',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedAddress.flatNo}, ${selectedAddress.area}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Add delivery address',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
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
              ),
              const SizedBox(height: 16),

              // Special instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Special Instructions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Any special requests for this order?',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price summary
              PriceSummaryCard(
                subtotal: cartState.subtotal,
                deliveryFee: cartState.deliveryFee,
                total: cartState.total,
              ),

              // Free delivery hint
              if (cartState.subtotal < AppConfig.deliveryFeeThreshold) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add ${AppConfig.currencySymbol}${(AppConfig.deliveryFeeThreshold - cartState.subtotal).toStringAsFixed(0)} more for free delivery',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Proceed to Pay button
        Container(
          padding: const EdgeInsets.all(16),
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
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedAddress != null
                    ? () => context.push(
                        '/checkout',
                        extra: {
                          'specialInstructions': _instructionsController.text
                              .trim(),
                        },
                      )
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
                  selectedAddress != null
                      ? 'Proceed to Pay ${AppConfig.currencySymbol}${cartState.total.toStringAsFixed(0)}'
                      : 'Add Address to Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
