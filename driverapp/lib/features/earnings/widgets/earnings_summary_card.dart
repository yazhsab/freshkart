import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';

class EarningsSummaryCard extends StatelessWidget {
  final double totalEarnings;
  final int deliveryCount;
  final double totalKm;
  final double baseEarnings;
  final double bonusEarnings;

  const EarningsSummaryCard({
    super.key,
    required this.totalEarnings,
    required this.deliveryCount,
    required this.totalKm,
    required this.baseEarnings,
    required this.bonusEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DeliveryColors.primaryDark, DeliveryColors.earningsTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DeliveryColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyUtil.format(totalEarnings),
            style: GoogleFonts.notoSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'From $deliveryCount deliveries \u2022 ${totalKm.toStringAsFixed(1)} km',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BreakdownItem(
                  label: 'Base',
                  value: CurrencyUtil.format(baseEarnings),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withOpacity(0.2),
                ),
                _BreakdownItem(
                  label: 'Bonus',
                  value: CurrencyUtil.format(bonusEarnings),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withOpacity(0.2),
                ),
                _BreakdownItem(
                  label: 'Net',
                  value: CurrencyUtil.format(totalEarnings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
