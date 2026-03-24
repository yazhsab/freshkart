import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/csv_export.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/export_button.dart';
import '../shared/widgets/filter_chip_row.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/stat_card.dart';
import '../shared/widgets/status_badge.dart';
import 'vendor_payouts_provider.dart';

class VendorPayoutsScreen extends ConsumerWidget {
  const VendorPayoutsScreen({super.key});

  static const _periodLabels = {
    PayoutPeriod.thisWeek: 'This Week',
    PayoutPeriod.lastWeek: 'Last Week',
    PayoutPeriod.thisMonth: 'This Month',
    PayoutPeriod.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(vendorPayoutPeriodProvider);
    final payoutsAsync = ref.watch(vendorPayoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SectionHeader(
            title: 'Vendor Payouts',
            subtitle: 'Manage vendor payments and commissions',
            actions: [
              payoutsAsync.when(
                data: (data) => ExportButton(
                  onPressed: () => _exportCSV(data),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          // Period filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilterChipRow(
                    options: _periodLabels.values.toList(),
                    selected: _periodLabels[selectedPeriod]!,
                    onSelected: (label) {
                      final entry = _periodLabels.entries
                          .firstWhere((e) => e.value == label);
                      if (entry.key == PayoutPeriod.custom) {
                        _pickDateRange(context, ref);
                      } else {
                        ref
                            .read(vendorPayoutPeriodProvider.notifier)
                            .set(entry.key);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: payoutsAsync.when(
              loading: () => const LoadingShimmer(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Error: $e'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(vendorPayoutsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Summary cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        final cards = [
                          StatCard(
                            title: 'Total GMV',
                            value: formatINRCompact(data.totalGmv),
                            icon: Icons.shopping_bag_outlined,
                            accentColor: AppColors.primary,
                          ),
                          StatCard(
                            title: 'Commission (10%)',
                            value: formatINRCompact(data.totalCommission),
                            icon: Icons.percent,
                            accentColor: AppColors.secondary,
                          ),
                          StatCard(
                            title: 'To Pay',
                            value: formatINRCompact(data.totalToPay),
                            icon: Icons.account_balance_wallet_outlined,
                            accentColor: AppColors.statusConfirmed,
                          ),
                          StatCard(
                            title: 'Paid',
                            value: formatINRCompact(data.totalPaid),
                            icon: Icons.check_circle_outline,
                            accentColor: AppColors.statusDelivered,
                          ),
                          StatCard(
                            title: 'Pending',
                            value: formatINRCompact(data.totalPending),
                            icon: Icons.pending_outlined,
                            accentColor: AppColors.paymentPending,
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            children: cards
                                .map((c) => Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: c,
                                      ),
                                    ))
                                .toList(),
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: cards
                              .map((c) => SizedBox(width: 180, child: c))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Data table
                    if (data.rows.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No payouts for this period',
                        subtitle:
                            'There are no delivered orders in the selected period',
                      )
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(AppColors.background),
                            headingRowHeight: 44,
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 52,
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text('Vendor')),
                              DataColumn(
                                  label: Text('Orders'), numeric: true),
                              DataColumn(
                                  label: Text('Gross'), numeric: true),
                              DataColumn(
                                  label: Text('Commission'), numeric: true),
                              DataColumn(
                                  label: Text('Net'), numeric: true),
                              DataColumn(label: Text('Last Paid')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Action')),
                            ],
                            rows: data.rows.map((row) {
                              return DataRow(cells: [
                                DataCell(Text(
                                  row.shopName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )),
                                DataCell(Text(
                                  '${row.orderCount}',
                                  style: const TextStyle(fontSize: 13),
                                )),
                                DataCell(Text(
                                  formatINR(row.grossAmount),
                                  style: const TextStyle(fontSize: 13),
                                )),
                                DataCell(Text(
                                  formatINR(row.commissionAmount),
                                  style: const TextStyle(fontSize: 13),
                                )),
                                DataCell(Text(
                                  formatINR(row.netAmount),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )),
                                DataCell(Text(
                                  row.lastPaidDate ?? '--',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                )),
                                DataCell(
                                  StatusBadge(
                                    status: row.status,
                                    type: 'payment',
                                  ),
                                ),
                                DataCell(
                                  row.status == 'paid'
                                      ? const Icon(
                                          Icons.check_circle,
                                          size: 20,
                                          color: AppColors.statusDelivered,
                                        )
                                      : _MarkPaidButton(row: row),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );
    if (picked != null) {
      ref.read(vendorPayoutCustomRangeProvider.notifier).set(
            PayoutDateRange(start: picked.start, end: picked.end),
          );
      ref.read(vendorPayoutPeriodProvider.notifier).set(PayoutPeriod.custom);
    }
  }

  void _exportCSV(VendorPayoutsSummary data) {
    final headers = [
      'Vendor',
      'Orders',
      'Gross (INR)',
      'Commission (INR)',
      'Net (INR)',
      'Last Paid',
      'Status',
    ];
    final rows = data.rows
        .map((r) => [
              r.shopName,
              r.orderCount,
              r.grossAmount.toStringAsFixed(2),
              r.commissionAmount.toStringAsFixed(2),
              r.netAmount.toStringAsFixed(2),
              r.lastPaidDate ?? '',
              r.status,
            ])
        .toList();
    exportToCSV('vendor_payouts.csv', headers, rows);
  }
}

// ── Mark Paid Button ────────────────────────────────────────────

class _MarkPaidButton extends ConsumerStatefulWidget {
  const _MarkPaidButton({required this.row});
  final VendorPayoutRow row;

  @override
  ConsumerState<_MarkPaidButton> createState() => _MarkPaidButtonState();
}

class _MarkPaidButtonState extends ConsumerState<_MarkPaidButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: _loading ? null : _markPaid,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Mark Paid'),
      ),
    );
  }

  Future<void> _markPaid() async {
    final refController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay ${formatINR(widget.row.netAmount)} to ${widget.row.shopName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                labelText: 'Payment Reference (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., UTR number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      refController.dispose();
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(vendorPayoutActionsProvider.notifier).markPaid(
            vendorId: widget.row.vendorId,
            grossAmount: widget.row.grossAmount,
            commissionAmount: widget.row.commissionAmount,
            netAmount: widget.row.netAmount,
            paymentReference: refController.text.trim().isEmpty
                ? null
                : refController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      refController.dispose();
      if (mounted) setState(() => _loading = false);
    }
  }
}
