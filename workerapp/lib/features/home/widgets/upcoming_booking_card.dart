import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/core/utils/date_util.dart';
import 'package:freshkart_worker/shared/widgets/status_badge.dart';

class UpcomingBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;

  const UpcomingBookingCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WorkerColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.build,
                color: WorkerColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceName ?? 'Service',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateUtil.relativeDay(booking.scheduledDate)} • ${booking.slotFormatted}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtil.format(booking.displayAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: booking.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
