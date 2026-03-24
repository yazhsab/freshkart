import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/stat_card.dart';
import '../shared/widgets/section_header.dart';
import 'analytics_provider.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/orders_by_hour_chart.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/top_vendors_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const _periods = [
    ('today', 'Today'),
    ('7days', '7 Days'),
    ('30days', '30 Days'),
    ('3months', '3 Months'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final asyncData = ref.watch(analyticsProvider(period));

    return Column(
      children: [
        SectionHeader(
          title: 'Analytics',
          subtitle: 'Platform performance overview',
          actions: [
            IconButton(
              onPressed: () => ref.invalidate(analyticsProvider(period)),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
            ),
          ],
        ),
        // Period tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: _periods.map((p) {
              final isSelected = p.$1 == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    p.$2,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      ref.read(analyticsPeriodProvider.notifier).set(p.$1),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Content
        Expanded(
          child: asyncData.when(
            loading: () => const LoadingShimmer(),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40,
                      color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load analytics: $e'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(analyticsProvider(period)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (data) => _AnalyticsBody(data: data),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Two columns: Grocery + Services ──────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _GroceryColumn(data: data)),
                    const SizedBox(width: 16),
                    Expanded(child: _ServiceColumn(data: data)),
                  ],
                );
              }
              return Column(
                children: [
                  _GroceryColumn(data: data),
                  const SizedBox(height: 16),
                  _ServiceColumn(data: data),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // ── Combined GMV section ───────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text('Combined GMV',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    Text(
                      formatINRCompact(data.combinedGMV),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                        label: 'Grocery',
                        value: formatINRCompact(data.groceryRevenue),
                        color: AppColors.primary),
                    const SizedBox(width: 24),
                    _MiniStat(
                        label: 'Services',
                        value: formatINRCompact(data.serviceRevenue),
                        color: AppColors.secondary),
                    const SizedBox(width: 24),
                    _MiniStat(
                        label: 'Total Transactions',
                        value:
                            '${data.totalOrders + data.totalBookings}',
                        color: AppColors.textPrimary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Revenue chart ──────────────────────────────────
          RevenueChart(
            groceryData: data.dailyGroceryRevenue,
            serviceData: data.dailyServiceRevenue,
          ),
          const SizedBox(height: 24),
          // ── Orders by hour + Category donut ────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: OrdersByHourChart(data: data.ordersByHour)),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            CategoryDonutChart(data: data.categoryShares)),
                  ],
                );
              }
              return Column(
                children: [
                  OrdersByHourChart(data: data.ordersByHour),
                  const SizedBox(height: 16),
                  CategoryDonutChart(data: data.categoryShares),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // ── Top vendors ────────────────────────────────────
          TopVendorsChart(data: data.topVendors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Grocery column ───────────────────────────────────────────────

class _GroceryColumn extends StatelessWidget {
  const _GroceryColumn({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('Grocery',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          _KPITile(
              label: 'Total Orders',
              value: data.totalOrders.toString(),
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary),
          _KPITile(
              label: 'Revenue',
              value: formatINRCompact(data.groceryRevenue),
              icon: Icons.currency_rupee_rounded,
              color: AppColors.primary),
          _KPITile(
              label: 'Avg. Order Value',
              value: formatINR(data.groceryAvgOrder),
              icon: Icons.analytics_outlined,
              color: AppColors.primary),
          _KPITile(
              label: 'Delivered',
              value: data.groceryDelivered.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.statusDelivered),
          _KPITile(
              label: 'Cancelled',
              value: data.groceryCancelled.toString(),
              icon: Icons.cancel_outlined,
              color: AppColors.error),
        ],
      ),
    );
  }
}

// ── Service column ───────────────────────────────────────────────

class _ServiceColumn extends StatelessWidget {
  const _ServiceColumn({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_repair_service_outlined,
                    size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 8),
              const Text('Services',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 16),
          _KPITile(
              label: 'Total Bookings',
              value: data.totalBookings.toString(),
              icon: Icons.calendar_month_outlined,
              color: AppColors.secondary),
          _KPITile(
              label: 'Revenue',
              value: formatINRCompact(data.serviceRevenue),
              icon: Icons.currency_rupee_rounded,
              color: AppColors.secondary),
          _KPITile(
              label: 'Avg. Booking Value',
              value: formatINR(data.serviceAvgBooking),
              icon: Icons.analytics_outlined,
              color: AppColors.secondary),
          _KPITile(
              label: 'Completed',
              value: data.serviceCompleted.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.statusCompleted),
          _KPITile(
              label: 'Cancelled',
              value: data.serviceCancelled.toString(),
              icon: Icons.cancel_outlined,
              color: AppColors.error),
        ],
      ),
    );
  }
}

// ── KPI tile ─────────────────────────────────────────────────────

class _KPITile extends StatelessWidget {
  const _KPITile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Mini stat ────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
