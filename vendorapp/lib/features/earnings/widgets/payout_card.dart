import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/utils/date_util.dart';
import 'package:freshkart_vendor/features/earnings/providers/earnings_provider.dart';

class PayoutCard extends StatefulWidget {
  final PayoutModel payout;
  final VoidCallback? onTap;

  const PayoutCard({super.key, required this.payout, this.onTap});

  @override
  State<PayoutCard> createState() => _PayoutCardState();
}

class _PayoutCardState extends State<PayoutCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final payout = widget.payout;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: VendorColors.divider),
      ),
      color: VendorColors.surface,
      child: InkWell(
        onTap: () {
          if (payout.orders.isNotEmpty) {
            setState(() => _isExpanded = !_isExpanded);
          }
          widget.onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          payout.periodLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: VendorColors.textPrimary,
                          ),
                        ),
                      ),
                      _StatusBadge(status: payout.status),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gross | Commission | Net
                  Row(
                    children: [
                      _AmountChip(
                        label: 'Gross',
                        amount: payout.grossAmount,
                        color: VendorColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _AmountChip(
                        label: 'Commission',
                        amount: -payout.commissionAmount,
                        color: VendorColors.error,
                        prefix: '-',
                      ),
                      const SizedBox(width: 8),
                      _AmountChip(
                        label: 'Net',
                        amount: payout.netAmount,
                        color: VendorColors.earningsGreen,
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Paid date or processing text
                  if (payout.status == 'paid' && payout.paidOn != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: VendorColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Paid on ${DateUtil.formatDate(payout.paidOn!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: VendorColors.textSecondary,
                          ),
                        ),
                        if (payout.referenceNumber != null) ...[
                          const Text(
                            ' \u2022 ',
                            style: TextStyle(color: VendorColors.textHint),
                          ),
                          Text(
                            'Ref: ${payout.referenceNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: VendorColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else if (payout.status == 'pending' ||
                      payout.status == 'processing') ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              VendorColors.pendingAmber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Processing \u2014 expected ${_nextMonday()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: VendorColors.pendingAmber,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Expand/collapse indicator
                  if (payout.orders.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: VendorColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Expanded order breakdown
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildOrderBreakdown(payout),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderBreakdown(PayoutModel payout) {
    return Container(
      decoration: const BoxDecoration(
        color: VendorColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: VendorColors.divider),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Order Breakdown',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VendorColors.textSecondary,
              ),
            ),
          ),
          ...payout.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: VendorColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Text(
                    CurrencyUtil.formatPrice(order.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      color: VendorColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${CurrencyUtil.formatPrice(order.commission)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: VendorColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _nextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final monday = now.add(
      Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
    );
    return DateFormat('dd MMM').format(monday);
  }
}

// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------

class _AmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;
  final String prefix;

  const _AmountChip({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: VendorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$prefix${CurrencyUtil.formatPrice(amount.abs())}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'paid':
        bgColor = VendorColors.primary.withValues(alpha: 0.12);
        textColor = VendorColors.primary;
        label = 'Paid';
        break;
      case 'processing':
        bgColor = VendorColors.pendingAmber.withValues(alpha: 0.12);
        textColor = VendorColors.pendingAmber;
        label = 'Processing';
        break;
      case 'pending':
      default:
        bgColor = VendorColors.newOrder.withValues(alpha: 0.12);
        textColor = VendorColors.newOrder;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
