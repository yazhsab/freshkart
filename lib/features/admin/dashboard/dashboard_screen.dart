import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/dashboard_stats.dart';
import '../../../core/utils/currency.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/section_header.dart';
import 'dashboard_provider.dart';
import 'widgets/activity_feed.dart';
import 'widgets/alerts_panel.dart';
import 'widgets/kpi_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 60),
      (_) => ref.invalidate(dashboardProvider),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncStats = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: asyncStats.when(
        loading: () => const LoadingShimmer(height: 600),
        error: (e, _) => _ErrorView(
          error: e.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (stats) => _DashboardBody(stats: stats),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Main dashboard body ───────────────────────────────────────────────
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isDesktop = w >= 1100;
        final isTablet = w >= 640 && w < 1100;
        final kpiColumns = isDesktop ? 4 : (isTablet ? 2 : 1);
        final padding = isDesktop ? 24.0 : 16.0;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ExecutiveSnapshotCard(stats: stats, isDesktop: isDesktop),
                  const SizedBox(height: 24),
                  // ── SECTION A: KPI StatCards ────────────────────────
                  const SectionHeader(
                    title: 'Dashboard Overview',
                    subtitle: 'Real-time metrics across grocery and services',
                  ),
                  const SizedBox(height: 8),
                  _KpiSection(stats: stats, columns: kpiColumns),
                  const SizedBox(height: 24),

                  // ── SECTION B: Charts ──────────────────────────────
                  _ChartsSection(stats: stats, isDesktop: isDesktop),
                  const SizedBox(height: 24),

                  // ── SECTION C: Activity Feed + Alerts ──────────────
                  _ActivityAlertsSection(stats: stats, isDesktop: isDesktop),
                  const SizedBox(height: 24),

                  // ── SECTION D: Quick Actions ───────────────────────
                  _QuickActionsRow(stats: stats),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExecutiveSnapshotCard extends StatelessWidget {
  const _ExecutiveSnapshotCard({required this.stats, required this.isDesktop});

  final DashboardStats stats;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final metricCards = [
      _SnapshotMetric(
        label: 'Total GMV today',
        value: formatINRCompact(stats.totalGmvToday),
      ),
      _SnapshotMetric(
        label: 'Platform commission',
        value: formatINRCompact(stats.platformCommissionToday),
      ),
      _SnapshotMetric(label: 'Alerts', value: stats.alertCount.toString()),
    ];

    final summary = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sidebar, AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Today at a glance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'A tighter operational overview with the most important commercial signals up front.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: wide ? 34 : 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Orders, bookings, revenue and exceptions are now easier to scan before moving into detail.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          );

          final right = wide
              ? Row(
                  children: [
                    for (var i = 0; i < metricCards.length; i++) ...[
                      Expanded(child: metricCards[i]),
                      if (i < metricCards.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < metricCards.length; i++) ...[
                      metricCards[i],
                      if (i < metricCards.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 18), right],
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: left),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: right),
            ],
          );
        },
      ),
    );

    if (isDesktop) return summary;
    return summary;
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION A: KPI CARDS
// ═══════════════════════════════════════════════════════════════════════

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.stats, required this.columns});
  final DashboardStats stats;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('GROCERY'),
        const SizedBox(height: 8),
        _buildGrid(_groceryCards(), columns),
        const SizedBox(height: 16),
        _sectionLabel('SERVICES'),
        const SizedBox(height: 8),
        _buildGrid(_serviceCards(), columns),
      ],
    );
  }

  List<Widget> _groceryCards() {
    return [
      KpiCard(
        icon: Icons.receipt_long_rounded,
        title: 'Orders Today',
        value: stats.ordersToday.toString(),
        subtitle: 'Total grocery orders placed today',
        accentColor: AppColors.primary,
        iconBackgroundColor: const Color(0xFFE8F5E9),
      ),
      KpiCard(
        icon: Icons.currency_rupee_rounded,
        title: 'Grocery Revenue',
        value: formatINRCompact(stats.groceryRevenueToday),
        subtitle: formatINR(stats.groceryRevenueToday),
        accentColor: AppColors.primary,
        iconBackgroundColor: const Color(0xFFE8F5E9),
      ),
      KpiCard(
        icon: Icons.store_rounded,
        title: 'Active Vendors',
        value: stats.activeVendors.toString(),
        subtitle: '${stats.pendingVendors} pending approval',
        accentColor: AppColors.primary,
        iconBackgroundColor: const Color(0xFFE8F5E9),
        badgeCount: stats.pendingVendors,
      ),
      KpiCard(
        icon: Icons.delivery_dining_rounded,
        title: 'Agents Online',
        value: stats.deliveryAgentsOnline.toString(),
        subtitle: 'Delivery agents currently active',
        accentColor: AppColors.primary,
        iconBackgroundColor: const Color(0xFFE8F5E9),
      ),
    ];
  }

  List<Widget> _serviceCards() {
    return [
      KpiCard(
        icon: Icons.calendar_month_rounded,
        title: 'Bookings Today',
        value: stats.bookingsToday.toString(),
        subtitle: 'Service bookings placed today',
        accentColor: AppColors.secondary,
        iconBackgroundColor: const Color(0xFFFFF8E1),
      ),
      KpiCard(
        icon: Icons.currency_rupee_rounded,
        title: 'Service Revenue',
        value: formatINRCompact(stats.serviceRevenueToday),
        subtitle: formatINR(stats.serviceRevenueToday),
        accentColor: AppColors.secondary,
        iconBackgroundColor: const Color(0xFFFFF8E1),
      ),
      KpiCard(
        icon: Icons.engineering_rounded,
        title: 'Active Workers',
        value: stats.activeWorkers.toString(),
        subtitle: '${stats.pendingBgvWorkers} pending BGV',
        accentColor: AppColors.secondary,
        iconBackgroundColor: const Color(0xFFFFF8E1),
        badgeCount: stats.pendingBgvWorkers,
      ),
      KpiCard(
        icon: Icons.warning_amber_rounded,
        title: 'Alerts',
        value: stats.alertCount.toString(),
        subtitle: '${stats.failedPayments} failed payments',
        accentColor: stats.alertCount > 0
            ? AppColors.error
            : AppColors.textSecondary,
        iconBackgroundColor: stats.alertCount > 0
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFF3F4F6),
      ),
    ];
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildGrid(List<Widget> cards, int cols) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((card) {
        return SizedBox(
          width: cols == 1
              ? double.infinity
              : cols == 2
              ? 340
              : 260,
          child: card,
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION B: CHARTS
// ═══════════════════════════════════════════════════════════════════════

class _ChartsSection extends StatelessWidget {
  const _ChartsSection({required this.stats, required this.isDesktop});
  final DashboardStats stats;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final barChart = _ChartCard(
      title: 'Orders & Bookings — Last 7 Days',
      child: SizedBox(height: 220, child: _GroupedBarChart(stats: stats)),
    );
    final donutChart = _ChartCard(
      title: 'Revenue Split Today',
      child: SizedBox(height: 220, child: _DonutChart(stats: stats)),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: barChart),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: donutChart),
        ],
      );
    }

    return Column(children: [barChart, const SizedBox(height: 16), donutChart]);
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.42),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Grouped Bar Chart ─────────────────────────────────────────────────
class _GroupedBarChart extends StatelessWidget {
  const _GroupedBarChart({required this.stats});
  final DashboardStats stats;

  static final _dayFormat = DateFormat('EEE');

  @override
  Widget build(BuildContext context) {
    final orders = stats.ordersLast7Days;
    final bookings = stats.bookingsLast7Days;
    final maxY = _calcMaxY(orders, bookings);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              groupsSpace: 16,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.sidebar,
                  tooltipBorderRadius: BorderRadius.circular(6),
                  getTooltipItem: (group, groupIdx, rod, rodIdx) {
                    final label = rodIdx == 0 ? 'Orders' : 'Bookings';
                    return BarTooltipItem(
                      '$label: ${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= orders.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dayFormat.format(orders[idx].date),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0
                    ? (maxY / 4).ceilToDouble().clamp(1, double.infinity)
                    : 1,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(orders.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: orders[i].count.toDouble(),
                      color: AppColors.primary,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: i < bookings.length
                          ? bookings[i].count.toDouble()
                          : 0,
                      color: AppColors.secondary,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.primary, label: 'Grocery Orders'),
            SizedBox(width: 20),
            _LegendDot(color: AppColors.secondary, label: 'Service Bookings'),
          ],
        ),
      ],
    );
  }

  double _calcMaxY(List<DailyCount> a, List<DailyCount> b) {
    var max = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i].count > max) max = a[i].count;
      if (i < b.length && b[i].count > max) max = b[i].count;
    }
    return (max + 2).toDouble().clamp(5, double.infinity);
  }
}

// ── Donut Chart ───────────────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final grocery = stats.groceryRevenueToday;
    final service = stats.serviceRevenueToday;
    final commission = stats.platformCommissionToday;
    final total = grocery + service;
    final hasData = total > 0;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {},
                  ),
                  sections: hasData
                      ? [
                          PieChartSectionData(
                            value: grocery,
                            color: AppColors.primary,
                            radius: 28,
                            title: '',
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: service,
                            color: AppColors.secondary,
                            radius: 28,
                            title: '',
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: commission,
                            color: AppColors.statusConfirmed,
                            radius: 28,
                            title: '',
                            showTitle: false,
                          ),
                        ]
                      : [
                          PieChartSectionData(
                            value: 1,
                            color: AppColors.border,
                            radius: 28,
                            title: '',
                            showTitle: false,
                          ),
                        ],
                ),
              ),
              // Center label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total GMV',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatINRCompact(total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Legend with values
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            _LegendDot(
              color: AppColors.primary,
              label: 'Grocery ${formatINRCompact(grocery)}',
            ),
            _LegendDot(
              color: AppColors.secondary,
              label: 'Services ${formatINRCompact(service)}',
            ),
            _LegendDot(
              color: AppColors.statusConfirmed,
              label: 'Commission ${formatINRCompact(commission)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION C: ACTIVITY + ALERTS
// ═══════════════════════════════════════════════════════════════════════

class _ActivityAlertsSection extends StatelessWidget {
  const _ActivityAlertsSection({required this.stats, required this.isDesktop});
  final DashboardStats stats;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final activity = ActivityFeed(activityItems: stats.activityFeed);
    final alerts = AlertsPanel(
      failedPayments: stats.failedPayments,
      pendingVendorApprovals: stats.pendingVendorApprovals,
      unassignedBookings: stats.unassignedBookings,
      lowStockProducts: stats.lowStockProducts,
      onFailedPaymentsTap: () => context.go('/admin/orders'),
      onPendingVendorsTap: () => context.go('/admin/vendors'),
      onUnassignedBookingsTap: () => context.go('/admin/bookings'),
      onLowStockTap: () => context.go('/admin/products'),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: activity),
          const SizedBox(width: 16),
          Expanded(child: alerts),
        ],
      );
    }

    return Column(children: [activity, const SizedBox(height: 16), alerts]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION D: QUICK ACTIONS
// ═══════════════════════════════════════════════════════════════════════

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (stats.pendingVendorApprovals > 0)
              _QuickActionButton(
                icon: Icons.store_rounded,
                label:
                    'Approve pending vendors (${stats.pendingVendorApprovals})',
                color: AppColors.secondary,
                onTap: () => context.go('/admin/vendors'),
              ),
            if (stats.unassignedBookings > 0)
              _QuickActionButton(
                icon: Icons.calendar_month_rounded,
                label:
                    'Assign unassigned bookings (${stats.unassignedBookings})',
                color: AppColors.secondary,
                onTap: () => context.go('/admin/bookings'),
              ),
            if (stats.failedPayments > 0)
              _QuickActionButton(
                icon: Icons.error_outline_rounded,
                label: 'View failed payments (${stats.failedPayments})',
                color: AppColors.error,
                onTap: () => context.go('/admin/orders'),
              ),
            if (stats.lowStockProducts > 0)
              _QuickActionButton(
                icon: Icons.inventory_2_outlined,
                label: 'Restock low products (${stats.lowStockProducts})',
                color: const Color(0xFFFDD835),
                onTap: () => context.go('/admin/products'),
              ),
            _QuickActionButton(
              icon: Icons.campaign_rounded,
              label: 'Send bulk notification',
              color: AppColors.statusConfirmed,
              onTap: () => context.go('/admin/notifications'),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering
                ? widget.color.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.4)),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
