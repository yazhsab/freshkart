import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';
import 'package:freshkart_delivery/features/shared/widgets/status_badge.dart';

class HistoryCard extends StatelessWidget {
  final DeliveryOrderModel delivery;

  const HistoryCard({super.key, required this.delivery});

  double get _totalDistance =>
      (delivery.pickupDistanceKm ?? 0) + (delivery.dropDistanceKm ?? 0);

  double? get _rating {
    // Rating from delivery response data if available
    return null;
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
      child: InkWell(
        onTap: () => context.push('/history/${delivery.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Order number + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${delivery.orderNumber}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                  StatusBadge(
                    status: delivery.isDelivered
                        ? 'Delivered'
                        : delivery.isCancelled
                        ? 'Failed'
                        : delivery.status,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Vendor → Customer
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            delivery.vendorName ?? 'Vendor',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DeliveryColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: DeliveryColors.textSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            delivery.customerArea,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: DeliveryColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom row: Time, Distance, Earnings, Rating
              Row(
                children: [
                  // Time
                  Icon(
                    Icons.access_time,
                    size: 13,
                    color: DeliveryColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    delivery.createdAt != null
                        ? DateUtil.formatDateTime(delivery.createdAt!)
                        : '--',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                  const Spacer(),

                  // Distance
                  if (_totalDistance > 0) ...[
                    Icon(
                      Icons.route,
                      size: 13,
                      color: DeliveryColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${_totalDistance.toStringAsFixed(1)} km',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Earnings
                  Text(
                    CurrencyUtil.format(delivery.deliveryEarnings ?? 0),
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DeliveryColors.earningsTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
