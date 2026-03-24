import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/features/home/providers/home_provider.dart';
import 'package:freshkart_worker/features/home/widgets/availability_toggle_card.dart';
import 'package:freshkart_worker/features/home/widgets/earnings_snapshot.dart';
import 'package:freshkart_worker/features/home/widgets/stats_row.dart';
import 'package:freshkart_worker/features/home/widgets/upcoming_booking_card.dart';
import 'package:freshkart_worker/shared/widgets/connectivity_banner.dart';
import 'package:freshkart_worker/shared/widgets/shimmer_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final worker = state.worker;

    return Scaffold(
      backgroundColor: WorkerColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: -70,
                    right: -30,
                    child: _AmbientOrb(
                      size: 220,
                      color: WorkerColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: -60,
                    child: _AmbientOrb(
                      size: 180,
                      color: WorkerColors.bonusGold.withValues(alpha: 0.16),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: -70,
                    child: _AmbientOrb(
                      size: 230,
                      color: WorkerColors.primaryLight.withValues(alpha: 0.1),
                    ),
                  ),
                  if (state.isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ShimmerLoader.list(),
                    )
                  else
                    RefreshIndicator(
                      color: WorkerColors.primary,
                      onRefresh: () =>
                          ref.read(homeProvider.notifier).loadData(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                        children: [
                          _WorkerHero(
                            workerName:
                                worker?.name.split(' ').first ?? 'Worker',
                            city: worker?.city ?? '',
                            skillsCount: worker?.skills.length ?? 0,
                            isVerified: worker?.isBgvApproved ?? false,
                            onProfileTap: () => context.go('/profile'),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 16),
                            _InlineErrorCard(message: state.error!),
                          ],
                          const SizedBox(height: 16),
                          AvailabilityToggleCard(
                            isAvailable: worker?.isAvailable ?? false,
                            onToggle: (value) => ref
                                .read(homeProvider.notifier)
                                .toggleAvailability(value),
                          ),
                          const SizedBox(height: 16),
                          _QuickActionsStrip(
                            onBookingsTap: () => context.go('/bookings'),
                            onScheduleTap: () => context.go('/schedule'),
                            onEarningsTap: () => context.go('/earnings'),
                            onProfileTap: () => context.go('/profile'),
                          ),
                          if (worker != null) ...[
                            const SizedBox(height: 16),
                            StatsRow(
                              rating: worker.rating,
                              totalJobs: worker.completedJobs,
                              experience: worker.experienceYears,
                            ),
                            const SizedBox(height: 16),
                            _HighlightsStrip(worker: worker),
                          ],
                          if (state.activeBooking != null) ...[
                            const SizedBox(height: 18),
                            _SectionCard(
                              eyebrow: 'Live Work',
                              title: 'Active job in progress',
                              subtitle:
                                  'Resume the current assignment and keep updates on track.',
                              child: _ActiveJobBanner(
                                booking: state.activeBooking!,
                                onTap: () => context.push(
                                  '/job-in-progress/${state.activeBooking!.id}',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _SectionCard(
                            eyebrow: 'Money',
                            title: 'Earnings snapshot',
                            subtitle:
                                'Track today and this week from a cleaner financial view.',
                            child: EarningsSnapshot(
                              todayEarnings: state.todayEarnings,
                              weekEarnings: state.weekEarnings,
                            ),
                          ),
                          if (state.todayBookings.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _SectionCard(
                              eyebrow: 'Today',
                              title: "Today's schedule",
                              subtitle:
                                  '${state.todayBookings.length} booking${state.todayBookings.length == 1 ? '' : 's'} lined up and ready.',
                              child: Column(
                                children: state.todayBookings
                                    .map(
                                      (booking) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: UpcomingBookingCard(
                                          booking: booking,
                                          onTap: () => context.push(
                                            '/booking/${booking.id}',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (state.upcomingBookings.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _SectionCard(
                              eyebrow: 'Queue',
                              title: 'Upcoming bookings',
                              subtitle:
                                  'Keep the next jobs visible before the day gets busy.',
                              trailing: TextButton(
                                onPressed: () => context.go('/bookings'),
                                child: const Text('All bookings'),
                              ),
                              child: Column(
                                children: state.upcomingBookings
                                    .take(3)
                                    .map(
                                      (booking) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: UpcomingBookingCard(
                                          booking: booking,
                                          onTap: () => context.push(
                                            '/booking/${booking.id}',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
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

class _WorkerHero extends StatelessWidget {
  final String workerName;
  final String city;
  final int skillsCount;
  final bool isVerified;
  final VoidCallback onProfileTap;

  const _WorkerHero({
    required this.workerName,
    required this.city,
    required this.skillsCount,
    required this.isVerified,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            WorkerColors.primaryDark,
            WorkerColors.primary,
            WorkerColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: WorkerColors.primary.withValues(alpha: 0.24),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isVerified ? 'Verified pro' : 'Review in progress',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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
          Text(
            'Hello, $workerName',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            city.isEmpty
                ? 'Keep your availability updated and move through bookings with a cleaner, calmer daily workflow.'
                : 'Serving $city with a more polished field dashboard for bookings, schedule, and earnings.',
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
                      value: '$skillsCount',
                      label: 'Skills listed',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value: city.isEmpty ? 'Mobile' : city,
                      label: 'Primary city',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroMetric(
                      value: isVerified ? 'Cleared' : 'Review',
                      label: 'Status',
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
              fontSize: 17,
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
  final VoidCallback onBookingsTap;
  final VoidCallback onScheduleTap;
  final VoidCallback onEarningsTap;
  final VoidCallback onProfileTap;

  const _QuickActionsStrip({
    required this.onBookingsTap,
    required this.onScheduleTap,
    required this.onEarningsTap,
    required this.onProfileTap,
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
              child: _ActionTile(
                icon: Icons.assignment_rounded,
                label: 'Bookings',
                subtitle: 'Manage requests',
                accentColor: WorkerColors.primary,
                onTap: onBookingsTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.calendar_month_rounded,
                label: 'Schedule',
                subtitle: 'See the week',
                accentColor: WorkerColors.bonusGold,
                onTap: onScheduleTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Earnings',
                subtitle: 'Review payouts',
                accentColor: WorkerColors.earningsGreen,
                onTap: onEarningsTap,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.person_rounded,
                label: 'Profile',
                subtitle: 'Update details',
                accentColor: WorkerColors.primaryDark,
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
                fontWeight: FontWeight.w800,
                color: WorkerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WorkerColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightsStrip extends StatelessWidget {
  final dynamic worker;

  const _HighlightsStrip({required this.worker});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final width = compact
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _HighlightTile(
                icon: Icons.workspace_premium_rounded,
                label: worker.isBgvApproved ? 'Verified' : 'Pending review',
              ),
            ),
            SizedBox(
              width: width,
              child: _HighlightTile(
                icon: Icons.star_rounded,
                label: '${worker.rating.toStringAsFixed(1)} rating',
              ),
            ),
            SizedBox(
              width: width,
              child: _HighlightTile(
                icon: Icons.build_circle_outlined,
                label: '${worker.completedJobs} jobs done',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HighlightTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WorkerColors.divider.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: WorkerColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: WorkerColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            WorkerColors.surface.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WorkerColors.divider.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: WorkerColors.primary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: WorkerColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: WorkerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  final String message;

  const _InlineErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WorkerColors.jobCancelled.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: WorkerColors.jobCancelled.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: WorkerColors.jobCancelled,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: WorkerColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobBanner extends StatelessWidget {
  final dynamic booking;
  final VoidCallback onTap;

  const _ActiveJobBanner({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WorkerColors.primary,
              WorkerColors.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: WorkerColors.primary.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume current job',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.serviceName ?? 'Service'} • ${CurrencyUtil.format(booking.displayAmount)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
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
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
