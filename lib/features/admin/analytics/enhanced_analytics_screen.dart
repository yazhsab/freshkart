import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/supabase/client.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/csv_export.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/stat_card.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/export_button.dart';

// ── Enhanced Analytics Data ──────────────────────────────────────

class EnhancedAnalyticsData {
  final List<_SalesTrendPoint> salesTrend;
  final double commissionRevenue;
  final double deliveryFeeRevenue;
  final double orderRevenue;
  final List<_TopVendorRow> topVendors;
  final List<_StockAlertRow> stockAlerts;
  final int newCustomersThisMonth;
  final double repeatRate;
  final double avgOrderValue;
  final int totalCustomers;
  final int activeCustomers;

  EnhancedAnalyticsData({
    required this.salesTrend,
    required this.commissionRevenue,
    required this.deliveryFeeRevenue,
    required this.orderRevenue,
    required this.topVendors,
    required this.stockAlerts,
    required this.newCustomersThisMonth,
    required this.repeatRate,
    required this.avgOrderValue,
    required this.totalCustomers,
    required this.activeCustomers,
  });
}

class _SalesTrendPoint {
  final DateTime date;
  final double revenue;
  _SalesTrendPoint({required this.date, required this.revenue});
}

class _TopVendorRow {
  final String name;
  final double revenue;
  final int orders;
  final double avgOrderValue;
  _TopVendorRow({
    required this.name,
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
  });
}

class _StockAlertRow {
  final String productName;
  final String vendorName;
  final int currentStock;
  final int threshold;
  _StockAlertRow({
    required this.productName,
    required this.vendorName,
    required this.currentStock,
    required this.threshold,
  });
}

// ── Period Provider ──────────────────────────────────────────────

final _enhancedPeriodProvider =
    NotifierProvider<_PeriodNotifier, String>(_PeriodNotifier.new);

class _PeriodNotifier extends Notifier<String> {
  @override
  String build() => '30days';
  void set(String period) => state = period;
}

// ── Data Provider ────────────────────────────────────────────────

final _enhancedAnalyticsProvider =
    FutureProvider.family<EnhancedAnalyticsData, String>(
        (ref, period) async {
  final now = DateTime.now();
  final DateTime from;
  switch (period) {
    case '7days':
      from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
    case '30days':
      from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 30));
    case '90days':
      from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 90));
    default:
      from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 30));
  }

  final fromStr = from.toIso8601String();
  final monthStart =
      DateTime(now.year, now.month, 1).toIso8601String();

  // Run queries in parallel
  final results = await Future.wait([
    // 0: orders in period
    adminClient
        .from('orders')
        .select(
            'id, final_amount, delivery_fee, status, created_at, vendor_id, customer_id')
        .gte('created_at', fromStr),
    // 1: vendors
    adminClient.from('vendors').select('id, shop_name'),
    // 2: products with low stock
    adminClient
        .from('products')
        .select(
            'id, name, stock_quantity, low_stock_threshold, vendor_id, is_available')
        .eq('is_available', true),
    // 3: new customers this month
    adminClient
        .from('profiles')
        .select('id')
        .eq('role', 'customer')
        .gte('created_at', monthStart),
    // 4: all customers
    adminClient
        .from('profiles')
        .select('id')
        .eq('role', 'customer'),
    // 5: payouts for commission data
    adminClient
        .from('payouts')
        .select('commission_amount, gross_amount, net_amount')
        .gte('created_at', fromStr),
  ]);

  final orders = results[0] as List;
  final vendors = results[1] as List;
  final products = results[2] as List;
  final newCustomers = results[3] as List;
  final allCustomers = results[4] as List;
  final payouts = results[5] as List;

  // Vendor map
  final vendorMap = <String, String>{};
  for (final v in vendors) {
    vendorMap[v['id'] as String] = v['shop_name'] as String;
  }

  // Sales trend
  final dailyMap = <String, double>{};
  double totalRevenue = 0;
  double totalDeliveryFee = 0;
  final vendorRevMap = <String, double>{};
  final vendorOrderMap = <String, int>{};
  final customerOrderMap = <String, int>{};

  for (final o in orders) {
    final amount = ((o['final_amount'] as num?) ?? 0).toDouble();
    final fee = ((o['delivery_fee'] as num?) ?? 0).toDouble();
    final status = o['status'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(o['created_at'] as String? ?? '');
    final vendorId = o['vendor_id'] as String? ?? '';
    final customerId = o['customer_id'] as String? ?? '';

    if (status == 'delivered') {
      totalRevenue += amount;
      totalDeliveryFee += fee;

      if (createdAt != null) {
        final dayKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + amount;
      }

      vendorRevMap[vendorId] =
          (vendorRevMap[vendorId] ?? 0) + amount;
      vendorOrderMap[vendorId] =
          (vendorOrderMap[vendorId] ?? 0) + 1;
    }

    if (customerId.isNotEmpty) {
      customerOrderMap[customerId] =
          (customerOrderMap[customerId] ?? 0) + 1;
    }
  }

  // Commission revenue from payouts
  double commissionRevenue = 0;
  for (final p in payouts) {
    commissionRevenue +=
        ((p['commission_amount'] as num?) ?? 0).toDouble();
  }

  // Sales trend sorted
  final sortedDays = dailyMap.keys.toList()..sort();
  final salesTrend = sortedDays
      .map((d) => _SalesTrendPoint(
          date: DateTime.parse(d), revenue: dailyMap[d] ?? 0))
      .toList();

  // Top vendors (top 10)
  final vendorEntries = vendorRevMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topVendors = vendorEntries.take(10).map((e) {
    final orderCount = vendorOrderMap[e.key] ?? 1;
    return _TopVendorRow(
      name: vendorMap[e.key] ?? 'Unknown',
      revenue: e.value,
      orders: orderCount,
      avgOrderValue: e.value / orderCount,
    );
  }).toList();

  // Stock alerts
  final stockAlerts = <_StockAlertRow>[];
  for (final p in products) {
    final stock = p['stock_quantity'] as int? ?? 0;
    final threshold = p['low_stock_threshold'] as int? ?? 5;
    if (stock <= threshold) {
      stockAlerts.add(_StockAlertRow(
        productName: p['name'] as String? ?? '',
        vendorName:
            vendorMap[p['vendor_id'] as String? ?? ''] ?? 'Unknown',
        currentStock: stock,
        threshold: threshold,
      ));
    }
  }
  stockAlerts.sort((a, b) => a.currentStock.compareTo(b.currentStock));

  // Customer metrics
  final repeatCustomers =
      customerOrderMap.values.where((c) => c > 1).length;
  final totalOrderCustomers = customerOrderMap.length;
  final repeatRate = totalOrderCustomers > 0
      ? repeatCustomers / totalOrderCustomers * 100
      : 0.0;
  final deliveredOrders =
      orders.where((o) => o['status'] == 'delivered').length;
  final avgOrderValue =
      deliveredOrders > 0 ? totalRevenue / deliveredOrders : 0.0;

  return EnhancedAnalyticsData(
    salesTrend: salesTrend,
    commissionRevenue: commissionRevenue,
    deliveryFeeRevenue: totalDeliveryFee,
    orderRevenue: totalRevenue,
    topVendors: topVendors,
    stockAlerts: stockAlerts,
    newCustomersThisMonth: newCustomers.length,
    repeatRate: repeatRate,
    avgOrderValue: avgOrderValue,
    totalCustomers: allCustomers.length,
    activeCustomers: totalOrderCustomers,
  );
});

// ── Screen ───────────────────────────────────────────────────────

class EnhancedAnalyticsScreen extends ConsumerWidget {
  const EnhancedAnalyticsScreen({super.key});

  static const _periods = [
    ('7days', '7 Days'),
    ('30days', '30 Days'),
    ('90days', '90 Days'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_enhancedPeriodProvider);
    final asyncData = ref.watch(_enhancedAnalyticsProvider(period));

    return Column(
      children: [
        SectionHeader(
          title: 'Enhanced Analytics',
          subtitle: 'Sales trends, revenue breakdown & stock alerts',
          actions: [
            IconButton(
              onPressed: () =>
                  ref.invalidate(_enhancedAnalyticsProvider(period)),
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
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      ref.read(_enhancedPeriodProvider.notifier).set(p.$1),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
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
                  const Icon(Icons.error_outline,
                      size: 40, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load analytics: $e'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => ref
                        .invalidate(_enhancedAnalyticsProvider(period)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (data) => _EnhancedBody(data: data),
          ),
        ),
      ],
    );
  }
}

class _EnhancedBody extends StatelessWidget {
  const _EnhancedBody({required this.data});
  final EnhancedAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Customer metrics cards ────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'New Customers (Month)',
                  value: data.newCustomersThisMonth.toString(),
                  icon: Icons.person_add_outlined,
                  accentColor: AppColors.primary,
                  subtitle:
                      '${data.totalCustomers} total customers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Repeat Rate',
                  value: '${data.repeatRate.toStringAsFixed(1)}%',
                  icon: Icons.replay_rounded,
                  accentColor: AppColors.secondary,
                  subtitle:
                      '${data.activeCustomers} active customers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Avg Order Value',
                  value: formatINR(data.avgOrderValue),
                  icon: Icons.shopping_cart_outlined,
                  accentColor: AppColors.statusDelivered,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Sales trend line chart ─────────────────────────
          _SalesTrendChart(data: data.salesTrend),
          const SizedBox(height: 24),

          // ── Revenue breakdown + Top vendors ─────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _RevenueBreakdownChart(data: data)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _TopVendorsTable(
                            vendors: data.topVendors)),
                  ],
                );
              }
              return Column(
                children: [
                  _RevenueBreakdownChart(data: data),
                  const SizedBox(height: 16),
                  _TopVendorsTable(vendors: data.topVendors),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Stock alerts table ──────────────────────────────
          _StockAlertsTable(alerts: data.stockAlerts),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Sales Trend Chart ────────────────────────────────────────────

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.data});
  final List<_SalesTrendPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text('No sales data for this period',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].revenue));
      if (data[i].revenue > maxY) maxY = data[i].revenue;
    }
    if (maxY == 0) maxY = 1000;
    final interval = (maxY / 4).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trends',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: data.length > 10
                          ? (data.length / 6).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM').format(data[idx].date),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value >= 100000) {
                          return Text(
                            '\u20B9${(value / 100000).toStringAsFixed(1)}L',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary),
                          );
                        }
                        if (value >= 1000) {
                          return Text(
                            '\u20B9${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary),
                          );
                        }
                        return Text(
                          '\u20B9${value.toInt()}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: maxY * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: data.length <= 15,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        return LineTooltipItem(
                          '\u20B9${s.y.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue Breakdown Pie Chart ──────────────────────────────────

class _RevenueBreakdownChart extends StatelessWidget {
  const _RevenueBreakdownChart({required this.data});
  final EnhancedAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final total =
        data.commissionRevenue + data.deliveryFeeRevenue + data.orderRevenue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: total == 0
                ? const Center(
                    child: Text('No revenue data',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: data.orderRevenue,
                                color: AppColors.primary,
                                title:
                                    '${(data.orderRevenue / total * 100).toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: data.commissionRevenue,
                                color: AppColors.secondary,
                                title:
                                    '${(data.commissionRevenue / total * 100).toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: data.deliveryFeeRevenue,
                                color: AppColors.statusConfirmed,
                                title:
                                    '${(data.deliveryFeeRevenue / total * 100).toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                radius: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(
                            color: AppColors.primary,
                            label: 'Order Revenue',
                            value: formatINRCompact(data.orderRevenue),
                          ),
                          const SizedBox(height: 8),
                          _LegendItem(
                            color: AppColors.secondary,
                            label: 'Commission',
                            value: formatINRCompact(
                                data.commissionRevenue),
                          ),
                          const SizedBox(height: 8),
                          _LegendItem(
                            color: AppColors.statusConfirmed,
                            label: 'Delivery Fees',
                            value: formatINRCompact(
                                data.deliveryFeeRevenue),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

// ── Top Vendors Table ────────────────────────────────────────────

class _TopVendorsTable extends StatelessWidget {
  const _TopVendorsTable({required this.vendors});
  final List<_TopVendorRow> vendors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Vendors',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (vendors.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(
                child: Text('No vendor data',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...vendors.asMap().entries.map((entry) {
              final i = entry.key;
              final v = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: i < 3
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        v.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${v.orders} orders',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatINR(v.revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Stock Alerts Table ───────────────────────────────────────────

class _StockAlertsTable extends StatelessWidget {
  const _StockAlertsTable({required this.alerts});
  final List<_StockAlertRow> alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Stock Alerts (${alerts.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'All products are well stocked',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: (alerts.length.clamp(0, 10) * 44.0) + 44,
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 0,
                headingRowHeight: 40,
                dataRowHeight: 44,
                headingRowColor:
                    WidgetStateProperty.all(AppColors.background),
                columns: const [
                  DataColumn2(
                      label: Text('Product'), size: ColumnSize.L),
                  DataColumn2(
                      label: Text('Vendor'), size: ColumnSize.M),
                  DataColumn2(
                    label: Text('Stock'),
                    size: ColumnSize.S,
                    numeric: true,
                    fixedWidth: 80,
                  ),
                  DataColumn2(
                    label: Text('Threshold'),
                    size: ColumnSize.S,
                    numeric: true,
                    fixedWidth: 90,
                  ),
                ],
                rows: alerts.take(10).map((a) {
                  final isCritical = a.currentStock == 0;
                  return DataRow2(
                    cells: [
                      DataCell(
                        Text(
                          a.productName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCritical
                                ? AppColors.error
                                : AppColors.textPrimary,
                            fontWeight: isCritical
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      DataCell(Text(
                        a.vendorName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(
                        Text(
                          a.currentStock.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCritical
                                ? AppColors.error
                                : AppColors.statusReady,
                          ),
                        ),
                      ),
                      DataCell(Text(a.threshold.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
