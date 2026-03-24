import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/models/payout_model.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';

class PayoutCard extends StatelessWidget {
  final PayoutModel payout;

  const PayoutCard({super.key, required this.payout});

  Color get _statusColor {
    if (payout.isPaid) return const Color(0xFF43A047);
    if (payout.isProcessing) return const Color(0xFF1976D2);
    return const Color(0xFFFF8F00); // pending / amber
  }

  String get _statusLabel {
    if (payout.isPaid) return 'Paid';
    if (payout.isProcessing) return 'Processing';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DeliveryColors.divider, width: 1),
      ),
      color: DeliveryColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: week range + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week of ${DateUtil.formatShortDate(payout.weekStart)} \u2013 ${DateUtil.formatShortDate(payout.weekEnd)}',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Subtitle: deliveries + earnings
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: DeliveryColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${payout.deliveryCount} deliveries',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: DeliveryColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  CurrencyUtil.format(payout.totalAmount),
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.earningsTeal,
                  ),
                ),
              ],
            ),

            // Paid info
            if (payout.isPaid && payout.paidAt != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: DeliveryColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: DeliveryColors.stepDone,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paid on ${DateUtil.formatDate(payout.paidAt!)}',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (payout.referenceNumber != null &&
                  payout.referenceNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Text(
                      'Ref: ${payout.referenceNumber}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
