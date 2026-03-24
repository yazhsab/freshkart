import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';

class StatsRow extends StatelessWidget {
  final int todayDeliveries;
  final double todayEarnings;
  final double todayDistanceKm;

  const StatsRow({
    super.key,
    required this.todayDeliveries,
    required this.todayEarnings,
    required this.todayDistanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.local_shipping_rounded,
            value: '$todayDeliveries',
            label: 'deliveries',
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.account_balance_wallet_rounded,
            value: CurrencyUtil.format(todayEarnings),
            label: 'earned',
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.route_rounded,
            value: '${todayDistanceKm.toStringAsFixed(1)} km',
            label: 'travelled',
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: DeliveryColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.earningsTeal,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  color: DeliveryColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
