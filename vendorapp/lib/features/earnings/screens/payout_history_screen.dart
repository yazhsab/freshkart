import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/features/earnings/providers/earnings_provider.dart';
import 'package:freshkart_vendor/features/earnings/widgets/payout_card.dart';

class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutsProvider);

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: const Text('Payout History'),
        backgroundColor: VendorColors.surface,
        foregroundColor: VendorColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: payoutsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: VendorColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: VendorColors.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load payouts',
                style: TextStyle(fontSize: 16, color: VendorColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(payoutsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (payouts) {
          if (payouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: VendorColors.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No payouts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your payout history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: VendorColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Compute all-time totals
          final totalPaid = payouts
              .where((p) => p.status == 'paid')
              .fold<double>(0, (s, p) => s + p.netAmount);
          final totalCommission = payouts.fold<double>(
            0,
            (s, p) => s + p.commissionAmount,
          );

          return RefreshIndicator(
            color: VendorColors.primary,
            onRefresh: () async => ref.invalidate(payoutsProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Summary header
                _buildSummaryHeader(totalPaid, totalCommission),
                const SizedBox(height: 16),

                // Payout list
                ...payouts.map(
                  (payout) => PayoutCard(
                    payout: payout,
                    onTap: () {
                      context.push(
                        '/earnings/payouts/${payout.id}',
                        extra: payout,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(double totalPaid, double totalCommission) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VendorColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VendorColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 18,
                        color: VendorColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Paid Out',
                          style: TextStyle(
                            fontSize: 12,
                            color: VendorColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyUtil.formatPrice(totalPaid),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.earningsGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 44, color: VendorColors.divider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: VendorColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.percent,
                          size: 18,
                          color: VendorColors.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Commission',
                              style: TextStyle(
                                fontSize: 12,
                                color: VendorColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyUtil.formatPrice(totalCommission),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: VendorColors.error,
                              ),
                            ),
                          ],
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
    );
  }
}
