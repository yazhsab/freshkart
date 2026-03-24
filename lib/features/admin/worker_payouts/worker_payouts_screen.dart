import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'worker_payouts_provider.dart';

class WorkerPayoutsScreen extends ConsumerWidget {
  const WorkerPayoutsScreen({super.key});

  static const _periodLabels = {
    WorkerPayoutPeriod.thisWeek: 'This Week',
    WorkerPayoutPeriod.lastWeek: 'Last Week',
    WorkerPayoutPeriod.thisMonth: 'This Month',
    WorkerPayoutPeriod.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(workerPayoutPeriodProvider);
    final payoutsAsync = ref.watch(workerPayoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SectionHeader(
            title: 'Worker Payouts',
            subtitle: 'Manage worker payments, disputes, and adjustments',
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
                      if (entry.key == WorkerPayoutPeriod.custom) {
                        _pickDateRange(context, ref);
                      } else {
                        ref
                            .read(workerPayoutPeriodProvider.notifier)
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
                          ref.invalidate(workerPayoutsProvider),
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
                        final isWide = constraints.maxWidth > 1000;
                        final cards = [
                          StatCard(
                            title: 'Total GMV',
                            value: formatINRCompact(data.totalGmv),
                            icon: Icons.home_repair_service_outlined,
                            accentColor: AppColors.primary,
                          ),
                          StatCard(
                            title: 'Commission (20%)',
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
                          StatCard(
                            title: 'Disputes',
                            value: '${data.totalDisputes}',
                            icon: Icons.warning_amber_outlined,
                            accentColor: AppColors.statusDisputed,
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
                              .map((c) => SizedBox(width: 170, child: c))
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
                            'There are no completed bookings in the selected period',
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
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(label: Text('Worker')),
                              DataColumn(
                                  label: Text('Bookings'), numeric: true),
                              DataColumn(
                                  label: Text('Gross'), numeric: true),
                              DataColumn(
                                  label: Text('Commission'), numeric: true),
                              DataColumn(
                                  label: Text('Net'), numeric: true),
                              DataColumn(
                                  label: Text('Disputes'), numeric: true),
                              DataColumn(label: Text('Last Paid')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: data.rows.map((row) {
                              return DataRow(cells: [
                                DataCell(Text(
                                  row.workerName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )),
                                DataCell(Text(
                                  '${row.bookingCount}',
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
                                DataCell(
                                  row.disputeCount > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusDisputed
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${row.disputeCount}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppColors.statusDisputed,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                ),
                                DataCell(Text(
                                  row.lastPaidDate ?? '--',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                )),
                                DataCell(
                                  StatusBadge(
                                    status: row.status == 'on_hold'
                                        ? 'pending'
                                        : row.status,
                                    type: 'payment',
                                  ),
                                ),
                                DataCell(
                                  _WorkerPayoutActions(row: row),
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
      ref.read(workerPayoutCustomRangeProvider.notifier).set(
            WorkerDateTimeRange(start: picked.start, end: picked.end),
          );
      ref
          .read(workerPayoutPeriodProvider.notifier)
          .set(WorkerPayoutPeriod.custom);
    }
  }

  void _exportCSV(WorkerPayoutsSummary data) {
    final headers = [
      'Worker',
      'Bookings',
      'Gross (INR)',
      'Commission (INR)',
      'Net (INR)',
      'Disputes',
      'Last Paid',
      'Status',
    ];
    final rows = data.rows
        .map((r) => [
              r.workerName,
              r.bookingCount,
              r.grossAmount.toStringAsFixed(2),
              r.commissionAmount.toStringAsFixed(2),
              r.netAmount.toStringAsFixed(2),
              r.disputeCount,
              r.lastPaidDate ?? '',
              r.status,
            ])
        .toList();
    exportToCSV('worker_payouts.csv', headers, rows);
  }
}

// ── Worker Payout Actions ───────────────────────────────────────

class _WorkerPayoutActions extends ConsumerWidget {
  const _WorkerPayoutActions({required this.row});
  final WorkerPayoutRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (row.status == 'paid') {
      return const Icon(
        Icons.check_circle,
        size: 20,
        color: AppColors.statusDelivered,
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'mark_paid',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 18, color: AppColors.statusDelivered),
              SizedBox(width: 8),
              Text('Mark Paid'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'hold',
          child: Row(
            children: [
              Icon(Icons.pause_circle_outline,
                  size: 18, color: AppColors.paymentPending),
              SizedBox(width: 8),
              Text('Hold Payment'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'adjustment',
          child: Row(
            children: [
              Icon(Icons.tune, size: 18, color: AppColors.statusConfirmed),
              SizedBox(width: 8),
              Text('Add Adjustment'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'mark_paid':
            _showMarkPaidDialog(context, ref);
          case 'hold':
            _showHoldDialog(context, ref);
          case 'adjustment':
            _showAdjustmentDialog(context, ref);
        }
      },
    );
  }

  void _showMarkPaidDialog(BuildContext context, WidgetRef ref) {
    final refController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Pay ${formatINR(row.netAmount)} to ${row.workerName}?'),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(workerPayoutActionsProvider.notifier)
                    .markPaid(
                      workerId: row.workerId,
                      grossAmount: row.grossAmount,
                      commissionAmount: row.commissionAmount,
                      netAmount: row.netAmount,
                      paymentReference: refController.text.trim().isEmpty
                          ? null
                          : refController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment recorded')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error),
                  );
                }
              }
              refController.dispose();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _showHoldDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hold Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Hold payment of ${formatINR(row.netAmount)} for ${row.workerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for hold',
                border: OutlineInputBorder(),
                hintText: 'e.g., Pending dispute resolution',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(workerPayoutActionsProvider.notifier)
                    .holdPayment(
                      workerId: row.workerId,
                      netAmount: row.netAmount,
                      reason: reasonController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment held')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error),
                  );
                }
              }
              reasonController.dispose();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paymentPending),
            child: const Text('Hold'),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Adjustment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a payment adjustment for ${row.workerName}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (INR)',
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
                hintText: 'Use negative for deductions',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Bonus, penalty, correction',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(amountController.text.trim());
              if (amount == null || reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref
                    .read(workerPayoutActionsProvider.notifier)
                    .addAdjustment(
                      workerId: row.workerId,
                      amount: amount,
                      reason: reasonController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adjustment added')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error),
                  );
                }
              }
              amountController.dispose();
              reasonController.dispose();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusConfirmed),
            child: const Text('Add Adjustment'),
          ),
        ],
      ),
    );
  }
}
