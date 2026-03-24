import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/home/providers/home_provider.dart';
import 'package:freshkart_delivery/features/home/widgets/active_delivery_card.dart';
import 'package:freshkart_delivery/features/home/widgets/available_orders_list.dart';
import 'package:freshkart_delivery/features/home/widgets/earnings_today_card.dart';
import 'package:freshkart_delivery/features/home/widgets/online_toggle_card.dart';
import 'package:freshkart_delivery/features/home/widgets/stats_row.dart';
import 'package:freshkart_delivery/features/shared/widgets/battery_warning_banner.dart';
import 'package:freshkart_delivery/features/shared/widgets/connectivity_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeProvider.notifier).initialize();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(homeProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    ref.listen<HomeState>(homeProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: DeliveryColors.newOrder,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      body: ConnectivityBanner(
        child: Column(
          children: [
            BatteryWarningBanner(batteryLevel: state.batteryLevel),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: -70,
                    right: -20,
                    child: _AmbientOrb(
                      size: 220,
                      color: DeliveryColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  Positioned(
                    top: 190,
                    left: -60,
                    child: _AmbientOrb(
                      size: 180,
                      color: DeliveryColors.bonusGold.withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    right: -70,
                    child: _AmbientOrb(
                      size: 230,
                      color: DeliveryColors.primaryLight.withValues(alpha: 0.1),
                    ),
                  ),
                  if (state.isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: DeliveryColors.primary,
                      ),
                    )
                  else
                    RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: DeliveryColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                        children: [
                          _DeliveryHero(
                            isOnline: state.isOnline,
                            batteryLevel: state.batteryLevel,
                            availableOrdersCount: state.availableOrders.length,
                            hasActiveDelivery: state.activeDelivery != null,
                            onProfileTap: () => context.push('/profile'),
                          ),
                          const SizedBox(height: 16),
                          const OnlineToggleCard(),
                          const SizedBox(height: 16),
                          _QuickActionsStrip(
                            onHistoryTap: () => context.go('/history'),
                            onEarningsTap: () => context.go('/earnings'),
                            onProfileTap: () => context.push('/profile'),
                          ),
                          if (state.activeDelivery != null) ...[
                            const SizedBox(height: 18),
                            const _SectionHeading(
                              eyebrow: 'Live Route',
                              title: 'Active pickup or drop',
                              subtitle:
                                  'Stay locked in on the current route and next handoff.',
                            ),
                            const SizedBox(height: 10),
                            ActiveDeliveryCard(order: state.activeDelivery!),
                          ],
                          if (state.isOnline &&
                              state.activeDelivery == null) ...[
                            const SizedBox(height: 18),
                            const _SectionHeading(
                              eyebrow: 'Dispatch',
                              title: 'Orders in your radius',
                              subtitle:
                                  'Fresh orders ready for pickup around your live zone.',
                            ),
                            const SizedBox(height: 10),
                            _PanelShell(
                              child: AvailableOrdersList(
                                orders: state.availableOrders,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          const _SectionHeading(
                            eyebrow: 'Performance',
                            title: 'Today\'s route board',
                            subtitle:
                                'Distance, deliveries, and earnings in one clear view.',
                          ),
                          const SizedBox(height: 10),
                          _PanelShell(
                            child: Column(
                              children: [
                                StatsRow(
                                  todayDeliveries: state.todayDeliveries,
                                  todayEarnings: state.todayEarnings,
                                  todayDistanceKm: state.todayDistanceKm,
                                ),
                                const SizedBox(height: 14),
                                EarningsTodayCard(
                                  earnings: state.todayEarnings,
                                  deliveries: state.todayDeliveries,
                                  distanceKm: state.todayDistanceKm,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHero extends StatelessWidget {
  final bool isOnline;
  final int batteryLevel;
  final int availableOrdersCount;
  final bool hasActiveDelivery;
  final VoidCallback onProfileTap;

  const _DeliveryHero({
    required this.isOnline,
    required this.batteryLevel,
    required this.availableOrdersCount,
    required this.hasActiveDelivery,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DeliveryColors.primaryDark,
            DeliveryColors.primary,
            DeliveryColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: DeliveryColors.primary.withValues(alpha: 0.24),
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
                  isOnline ? 'Dispatch live' : 'Standby mode',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: onProfileTap,
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Delivery cockpit',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasActiveDelivery
                ? 'A live route is in motion. Keep pickup timing and drop completion tight from here.'
                : 'Watch order flow, battery health, and daily output from one focused dispatch dashboard.',
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
                      value: '$availableOrdersCount',
                      label: 'Ready orders',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value: '$batteryLevel%',
                      label: 'Battery',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value: hasActiveDelivery ? 'Live' : 'Clear',
                      label: 'Route state',
                    ),
                  ),
                ],
              );
            },
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
              fontWeight: FontWeight.w700,
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
  final VoidCallback onHistoryTap;
  final VoidCallback onEarningsTap;
  final VoidCallback onProfileTap;

  const _QuickActionsStrip({
    required this.onHistoryTap,
    required this.onEarningsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.history_rounded,
                label: 'History',
                subtitle: 'Past drops',
                accentColor: DeliveryColors.primary,
                onTap: onHistoryTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Earnings',
                subtitle: 'Today and week',
                accentColor: DeliveryColors.bonusGold,
                onTap: onEarningsTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.person_rounded,
                label: 'Profile',
                subtitle: 'Account settings',
                accentColor: DeliveryColors.earningsTeal,
                onTap: onProfileTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionTile({
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
                fontWeight: FontWeight.w700,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: DeliveryColors.primary.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DeliveryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: DeliveryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PanelShell extends StatelessWidget {
  final Widget child;

  const _PanelShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            DeliveryColors.surface.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: DeliveryColors.divider.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
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
