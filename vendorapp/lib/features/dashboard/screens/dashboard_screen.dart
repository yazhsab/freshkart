import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/dashboard/providers/dashboard_provider.dart';
import 'package:freshkart_vendor/features/dashboard/widgets/earnings_card.dart';
import 'package:freshkart_vendor/features/dashboard/widgets/orders_summary_card.dart';
import 'package:freshkart_vendor/features/dashboard/widgets/shop_status_toggle.dart';
import 'package:freshkart_vendor/features/dashboard/widgets/stats_row.dart';
import 'package:freshkart_vendor/features/orders/widgets/new_order_banner.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final vendorId = SupabaseConfig.currentUser?.id;
    if (vendorId != null) {
      Future.microtask(() {
        ref.read(dashboardProvider.notifier).initialize(vendorId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final vendorId = SupabaseConfig.currentUser?.id ?? '';
    final pendingStream = ref.watch(pendingOrdersStreamProvider(vendorId));
    final weeklyRevenue = ref.watch(weeklyRevenueProvider);

    final pendingOrders = pendingStream.when(
      data: (orders) => orders,
      loading: () => <Map<String, dynamic>>[],
      error: (error, stackTrace) => <Map<String, dynamic>>[],
    );

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              VendorAppConfig.appName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: VendorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isShopOpen
                        ? VendorColors.primaryLight
                        : VendorColors.disabled,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (state.isShopOpen
                                    ? VendorColors.primaryLight
                                    : VendorColors.disabled)
                                .withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isShopOpen ? 'Store live now' : 'Store paused',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: state.isShopOpen
                        ? VendorColors.primary
                        : VendorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _AppBarAction(
            icon: Icons.currency_rupee_rounded,
            onTap: () => context.push('/earnings'),
          ),
          const SizedBox(width: 8),
          _AppBarAction(
            icon: Icons.storefront_rounded,
            onTap: () => context.go('/shop'),
          ),
          const SizedBox(width: 8),
          _AppBarAction(
            icon: Icons.refresh_rounded,
            onTap: () => ref.read(dashboardProvider.notifier).refreshStats(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _AmbientOrb(
              size: 220,
              color: VendorColors.primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 220,
            left: -70,
            child: _AmbientOrb(
              size: 190,
              color: VendorColors.pendingAmber.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: _AmbientOrb(
              size: 240,
              color: VendorColors.earningsGreen.withValues(alpha: 0.08),
            ),
          ),
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(color: VendorColors.primary),
            )
          else if (state.error != null)
            _DashboardErrorView(
              error: state.error!,
              onRetry: () =>
                  ref.read(dashboardProvider.notifier).refreshStats(),
            )
          else
            RefreshIndicator(
              onRefresh: () =>
                  ref.read(dashboardProvider.notifier).refreshStats(),
              color: VendorColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _DashboardHero(
                        isShopOpen: state.isShopOpen,
                        todayRevenue: state.todayRevenue,
                        pendingOrderCount: pendingOrders.length,
                        lowStockCount: state.lowStockCount,
                        onOrdersTap: () => context.go('/orders'),
                        onInventoryTap: () => context.go('/inventory'),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ShopStatusToggle(
                      isOpen: state.isShopOpen,
                      onToggle: (_) =>
                          ref.read(dashboardProvider.notifier).toggleShopOpen(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _QuickActionsStrip(
                        onOrdersTap: () => context.go('/orders'),
                        onInventoryTap: () => context.go('/inventory'),
                        onEarningsTap: () => context.push('/earnings'),
                        onShopTap: () => context.go('/shop'),
                      ),
                    ),
                  ),
                  if (pendingOrders.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: NewOrderBanner(
                          pendingCount: pendingOrders.length,
                          onTap: () => context.go('/orders'),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: StatsRow(
                        ordersToday: state.ordersToday,
                        todayRevenue: state.todayRevenue,
                        weekRevenue: state.weekRevenue,
                        rating: state.rating,
                        totalRatings: state.totalRatings,
                      ),
                    ),
                  ),
                  if (pendingOrders.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(
                        eyebrow: 'Operations',
                        title: 'Orders waiting for action',
                        subtitle:
                            'Keep handoff speed high during peak order flow.',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.list(
                        children: pendingOrders
                            .take(3)
                            .map(
                              (order) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: OrdersSummaryCard(
                                  order: order,
                                  onAccept: () {},
                                  onReject: () {},
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (state.lowStockCount > 0)
                    SliverToBoxAdapter(
                      child: _InventoryAlert(
                        lowStockCount: state.lowStockCount,
                        onTap: () => context.go('/inventory'),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: _SectionTitle(
                      eyebrow: 'Insights',
                      title: 'Revenue pulse',
                      subtitle:
                          'A cleaner weekly read on what your store is earning.',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      child: weeklyRevenue.when(
                        data: (data) => EarningsCard(dailyRevenues: data),
                        loading: () => const SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: VendorColors.primary,
                            ),
                          ),
                        ),
                        error: (error, stackTrace) => _DashboardErrorTile(
                          message: 'Revenue data is unavailable right now.',
                          onRetry: () => ref
                              .read(dashboardProvider.notifier)
                              .refreshStats(),
                        ),
                      ),
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

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            VendorColors.surface.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendorColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: VendorColors.textPrimary, size: 21),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final bool isShopOpen;
  final double todayRevenue;
  final int pendingOrderCount;
  final int lowStockCount;
  final VoidCallback onOrdersTap;
  final VoidCallback onInventoryTap;

  const _DashboardHero({
    required this.isShopOpen,
    required this.todayRevenue,
    required this.pendingOrderCount,
    required this.lowStockCount,
    required this.onOrdersTap,
    required this.onInventoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            VendorColors.primaryDark,
            VendorColors.primary,
            VendorColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: VendorColors.primary.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isShopOpen ? 'Store online' : 'Pause mode',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Run the store from one sharper control layer.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Today you have $pendingOrderCount order${pendingOrderCount == 1 ? '' : 's'} pending and ${VendorAppConfig.currency}${todayRevenue.toStringAsFixed(0)} already closed in sales.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final itemWidth = compact
                  ? (constraints.maxWidth - 10) / 2
                  : (constraints.maxWidth - 20) / 3;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value: '$pendingOrderCount',
                      label: 'Awaiting now',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value:
                          '${VendorAppConfig.currency}${todayRevenue.toStringAsFixed(0)}',
                      label: 'Sales today',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value: '$lowStockCount',
                      label: 'Low stock',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOrdersTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Review orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onInventoryTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: VendorColors.primary,
                  ),
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: const Text('Update stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsStrip extends StatelessWidget {
  final VoidCallback onOrdersTap;
  final VoidCallback onInventoryTap;
  final VoidCallback onEarningsTap;
  final VoidCallback onShopTap;

  const _QuickActionsStrip({
    required this.onOrdersTap,
    required this.onInventoryTap,
    required this.onEarningsTap,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final width = compact
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 30) / 4;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _QuickActionTile(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                subtitle: 'Approve faster',
                accentColor: VendorColors.newOrder,
                onTap: onOrdersTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _QuickActionTile(
                icon: Icons.inventory_2_rounded,
                label: 'Inventory',
                subtitle: 'Fix stock gaps',
                accentColor: VendorColors.pendingAmber,
                onTap: onInventoryTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _QuickActionTile(
                icon: Icons.currency_rupee_rounded,
                label: 'Earnings',
                subtitle: 'Payout pulse',
                accentColor: VendorColors.earningsGreen,
                onTap: onEarningsTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _QuickActionTile(
                icon: Icons.storefront_rounded,
                label: 'Shop',
                subtitle: 'Edit storefront',
                accentColor: VendorColors.primary,
                onTap: onShopTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.94),
              accentColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: VendorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: VendorColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: VendorColors.primary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: VendorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryAlert extends StatelessWidget {
  final int lowStockCount;
  final VoidCallback? onTap;

  const _InventoryAlert({required this.lowStockCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VendorColors.pendingAmber.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: VendorColors.pendingAmber.withValues(alpha: 0.22),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: VendorColors.lowStock,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '$lowStockCount item${lowStockCount == 1 ? '' : 's'} need stock updates before they affect live availability.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: VendorColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: VendorColors.lowStock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _DashboardErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: VendorColors.cancelledOrder.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: VendorColors.cancelledOrder.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: VendorColors.cancelledOrder,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dashboard unavailable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: VendorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: VendorColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: VendorColors.divider.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load chart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: VendorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
