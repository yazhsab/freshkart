import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/utils/date_util.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/features/earnings/providers/earnings_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String payoutId;
  final PayoutModel? payoutExtra;

  const TransactionDetailScreen({
    super.key,
    required this.payoutId,
    this.payoutExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the extra passed via navigation; fall back to provider lookup.
    final payout = payoutExtra ?? ref.watch(payoutByIdProvider(payoutId));

    if (payout == null) {
      return Scaffold(
        backgroundColor: VendorColors.background,
        appBar: AppBar(
          title: const Text('Payout Detail'),
          backgroundColor: VendorColors.surface,
          foregroundColor: VendorColors.textPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Payout not found',
            style: TextStyle(fontSize: 16, color: VendorColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: const Text('Payout Detail'),
        backgroundColor: VendorColors.surface,
        foregroundColor: VendorColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period & Status header
          _buildHeaderCard(payout),
          const SizedBox(height: 16),

          // Financial breakdown
          _buildFinancialBreakdown(payout),
          const SizedBox(height: 16),

          // Bank transfer details
          if (payout.status == 'paid') ...[
            _buildBankDetails(payout),
            const SizedBox(height: 16),
          ],

          // Order list
          _buildOrderList(payout),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------- Header Card ----------

  Widget _buildHeaderCard(PayoutModel payout) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: payout.status == 'paid'
              ? [VendorColors.primaryDark, VendorColors.primary]
              : [const Color(0xFF7B5E00), VendorColors.pendingAmber],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payout.periodLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  payout.status == 'paid'
                      ? 'Paid'
                      : payout.status == 'processing'
                      ? 'Processing'
                      : 'Pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Period dates
          Row(
            children: [
              const Icon(Icons.date_range, size: 16, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                '${DateUtil.formatDate(payout.periodStart)} \u2013 ${DateUtil.formatDate(payout.periodEnd)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Net amount large
          Text(
            CurrencyUtil.formatPrice(payout.netAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${payout.orders.length} orders in this period',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------- Financial Breakdown ----------

  Widget _buildFinancialBreakdown(PayoutModel payout) {
    final commissionPct = VendorAppConfig.platformCommissionPct;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _BreakdownRow(
            label: 'Gross Revenue',
            value: CurrencyUtil.formatPrice(payout.grossAmount),
            valueColor: VendorColors.textPrimary,
          ),
          const SizedBox(height: 8),

          _BreakdownRow(
            label: 'Platform Commission (${commissionPct.toStringAsFixed(0)}%)',
            value: '-${CurrencyUtil.formatPrice(payout.commissionAmount)}',
            valueColor: VendorColors.error,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: VendorColors.divider),
          ),

          _BreakdownRow(
            label: 'Net Earnings',
            value: CurrencyUtil.formatPrice(payout.netAmount),
            valueColor: VendorColors.earningsGreen,
            bold: true,
          ),
        ],
      ),
    );
  }

  // ---------- Bank Transfer Details ----------

  Widget _buildBankDetails(PayoutModel payout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance,
                size: 18,
                color: VendorColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Bank Transfer Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _DetailRow(
            label: 'Status',
            value: 'Completed',
            valueColor: VendorColors.primary,
          ),

          if (payout.paidOn != null)
            _DetailRow(
              label: 'Paid On',
              value: DateUtil.formatDateTime(payout.paidOn!),
            ),

          if (payout.referenceNumber != null)
            _DetailRow(
              label: 'Reference Number',
              value: payout.referenceNumber!,
              mono: true,
            ),

          if (payout.bankName != null)
            _DetailRow(label: 'Bank', value: payout.bankName!),

          if (payout.accountLast4 != null)
            _DetailRow(
              label: 'Account',
              value: '\u2022\u2022\u2022\u2022 ${payout.accountLast4}',
              mono: true,
            ),

          _DetailRow(
            label: 'Amount Transferred',
            value: CurrencyUtil.formatPrice(payout.netAmount),
            valueColor: VendorColors.earningsGreen,
            bold: true,
          ),
        ],
      ),
    );
  }

  // ---------- Order List ----------

  Widget _buildOrderList(PayoutModel payout) {
    if (payout.orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: VendorColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VendorColors.divider),
        ),
        child: const Center(
          child: Text(
            'Order details not available',
            style: TextStyle(fontSize: 14, color: VendorColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders (${payout.orders.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VendorColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Order',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Commission',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Net',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Order rows
          ...payout.orders.map((order) {
            final net = order.amount - order.commission;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: VendorColors.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateUtil.formatDate(order.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: VendorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      CurrencyUtil.formatPrice(order.amount),
                      style: const TextStyle(
                        fontSize: 12,
                        color: VendorColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '-${CurrencyUtil.formatPrice(order.commission)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: VendorColors.error,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      CurrencyUtil.formatPrice(net),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VendorColors.earningsGreen,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Totals row
          const Divider(color: VendorColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyUtil.formatPrice(payout.grossAmount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '-${CurrencyUtil.formatPrice(payout.commissionAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.error,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyUtil.formatPrice(payout.netAmount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.earningsGreen,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor = VendorColors.textPrimary,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: VendorColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = VendorColors.textPrimary,
    this.bold = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: VendorColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor,
                fontFamily: mono ? 'monospace' : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
