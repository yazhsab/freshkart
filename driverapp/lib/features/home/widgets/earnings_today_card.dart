import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';

class EarningsTodayCard extends StatelessWidget {
  final double earnings;
  final int deliveries;
  final double distanceKm;

  const EarningsTodayCard({
    super.key,
    required this.earnings,
    required this.deliveries,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/earnings'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DeliveryColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DeliveryColors.primary.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Earnings icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DeliveryColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: DeliveryColors.earningsTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Earnings text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s earnings',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyUtil.format(earnings),
                    style: GoogleFonts.notoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: DeliveryColors.earningsTeal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$deliveries deliveries \u2022 ${distanceKm.toStringAsFixed(1)} km',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: DeliveryColors.textSecondary.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
