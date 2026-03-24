import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';

class StatsRow extends StatelessWidget {
  final int ordersToday;
  final double todayRevenue;
  final double weekRevenue;
  final double rating;
  final int totalRatings;

  const StatsRow({
    super.key,
    required this.ordersToday,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.rating,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatCard(
            icon: Icons.shopping_bag_rounded,
            iconColor: VendorColors.confirmedOrder,
            label: "Today's Orders",
            value: ordersToday.toString(),
          ),
          _StatCard(
            icon: Icons.currency_rupee_rounded,
            iconColor: VendorColors.earningsGreen,
            label: "Today's Revenue",
            value:
                '${VendorAppConfig.currency}${todayRevenue.toStringAsFixed(0)}',
          ),
          _StatCard(
            icon: Icons.trending_up_rounded,
            iconColor: VendorColors.packingOrder,
            label: 'This Week',
            value:
                '${VendorAppConfig.currency}${weekRevenue.toStringAsFixed(0)}',
          ),
          _StatCard(
            icon: Icons.star_rounded,
            iconColor: VendorColors.pendingAmber,
            label: 'Rating ($totalRatings)',
            value: rating > 0 ? rating.toStringAsFixed(1) : '--',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: VendorColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
