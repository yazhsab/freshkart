import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class StockBadge extends StatelessWidget {
  final int quantity;
  final int lowStockThreshold;

  const StockBadge({
    super.key,
    required this.quantity,
    this.lowStockThreshold = 5,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;

    if (quantity == 0) {
      bgColor = VendorColors.outOfStock.withValues(alpha: 0.12);
      textColor = VendorColors.outOfStock;
      label = 'Out of stock';
    } else if (quantity <= lowStockThreshold) {
      bgColor = VendorColors.lowStock.withValues(alpha: 0.12);
      textColor = VendorColors.lowStock;
      label = '$quantity left';
    } else {
      bgColor = VendorColors.inStock.withValues(alpha: 0.12);
      textColor = VendorColors.inStock;
      label = '$quantity in stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
