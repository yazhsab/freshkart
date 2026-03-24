import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/features/orders/widgets/countdown_timer_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class OrdersSummaryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrdersSummaryCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString().substring(0, 8) ?? '---';
    final customerArea = order['delivery_address']?['area'] ?? 'Unknown area';
    final createdAt =
        DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final itemCount = (order['items'] as List?)?.length ?? 0;
    final totalAmount = (order['total_amount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.newOrder.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: VendorColors.newOrder.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Orange left border
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: VendorColors.newOrder,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Text(
                          '#$orderId',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          customerArea,
                          style: const TextStyle(
                            fontSize: 12,
                            color: VendorColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: VendorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Items + Amount
                    Text(
                      '$itemCount item${itemCount != 1 ? 's' : ''} • ${VendorAppConfig.currency}${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: VendorColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Timer + buttons
                    Row(
                      children: [
                        CountdownTimerWidget(
                          orderCreatedAt: createdAt,
                          totalSeconds: VendorAppConfig.orderAutoConfirmSeconds,
                          size: 40,
                          onTimeout: onAccept,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: VendorColors.cancelledOrder,
                                side: const BorderSide(
                                  color: VendorColors.cancelledOrder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: onAccept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VendorColors.primaryLight,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
