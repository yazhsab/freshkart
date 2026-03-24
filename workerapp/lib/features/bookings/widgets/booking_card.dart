import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/core/utils/date_util.dart';
import 'package:freshkart_worker/shared/widgets/status_badge.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: booking.isActive
                ? WorkerColors.primary.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: booking.isActive
              ? [
                  BoxShadow(
                    color: WorkerColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WorkerColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build,
                    color: WorkerColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName ?? 'Service',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        booking.customerName ?? 'Customer',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  DateUtil.relativeDay(booking.scheduledDate),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  booking.slotFormatted,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.areaOnly,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyUtil.format(booking.displayAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: WorkerColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
