import 'package:flutter/material.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

class PriceSummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double walletAmount;
  final double loyaltyDiscount;
  final double total;

  const PriceSummaryCard({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    this.walletAmount = 0,
    this.loyaltyDiscount = 0,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal
          _PriceRow(
            label: 'Item Total',
            amount: '${AppConfig.currencySymbol}${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),

          // Delivery fee
          _PriceRow(
            label: 'Delivery Fee',
            amount: deliveryFee == 0
                ? 'FREE'
                : '${AppConfig.currencySymbol}${deliveryFee.toStringAsFixed(2)}',
            amountColor: deliveryFee == 0 ? AppColors.primaryGreen : null,
          ),

          // Coupon Discount
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Coupon Discount',
              amount:
                  '-${AppConfig.currencySymbol}${discount.toStringAsFixed(2)}',
              amountColor: AppColors.primaryGreen,
            ),
          ],

          // Wallet
          if (walletAmount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Wallet',
              amount:
                  '-${AppConfig.currencySymbol}${walletAmount.toStringAsFixed(2)}',
              amountColor: AppColors.primaryGreen,
            ),
          ],

          // Loyalty Points
          if (loyaltyDiscount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Loyalty Points',
              amount:
                  '-${AppConfig.currencySymbol}${loyaltyDiscount.toStringAsFixed(2)}',
              amountColor: AppColors.primaryGreen,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${AppConfig.currencySymbol}${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color? amountColor;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: amountColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
