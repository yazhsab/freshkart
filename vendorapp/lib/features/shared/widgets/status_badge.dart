import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.icon,
  });

  // Order status factories
  factory StatusBadge.pending() =>
      const StatusBadge(label: 'Pending', color: VendorColors.newOrder);

  factory StatusBadge.confirmed() =>
      const StatusBadge(label: 'Confirmed', color: VendorColors.confirmedOrder);

  factory StatusBadge.packing() =>
      const StatusBadge(label: 'Packing', color: VendorColors.packingOrder);

  factory StatusBadge.ready() =>
      const StatusBadge(label: 'Ready', color: VendorColors.readyOrder);

  factory StatusBadge.delivered() => const StatusBadge(
    label: 'Delivered',
    color: VendorColors.primary,
    icon: Icons.check_circle_outline_rounded,
  );

  factory StatusBadge.cancelled() =>
      const StatusBadge(label: 'Cancelled', color: VendorColors.cancelledOrder);

  // Inventory status factories
  factory StatusBadge.inStock() =>
      const StatusBadge(label: 'In Stock', color: VendorColors.inStock);

  factory StatusBadge.lowStock() =>
      const StatusBadge(label: 'Low Stock', color: VendorColors.lowStock);

  factory StatusBadge.outOfStock() =>
      const StatusBadge(label: 'Out of Stock', color: VendorColors.outOfStock);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
