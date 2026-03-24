import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';
import 'package:freshkart_delivery/features/earnings/providers/earnings_provider.dart';
import 'package:freshkart_delivery/features/earnings/widgets/earnings_summary_card.dart';
import 'package:freshkart_delivery/features/earnings/widgets/daily_chart.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsState = ref.watch(earningsProvider);
    final notifier = ref.read(earningsProvider.notifier);

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Earnings',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            color: DeliveryColors.textPrimary,
          ),
        ),
        backgroundColor: DeliveryColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: earningsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DeliveryColors.primary),
            )
          : earningsState.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: DeliveryColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load earnings',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        notifier.fetchEarnings(earningsState.period),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: DeliveryColors.primary,
              onRefresh: () => notifier.fetchEarnings(earningsState.period),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period tabs
                    _buildPeriodTabs(earningsState, notifier),
                    const SizedBox(height: 16),

                    // Hero card
                    EarningsSummaryCard(
                      totalEarnings: earningsState.totalEarnings,
                      deliveryCount: earningsState.deliveryCount,
                      totalKm: earningsState.totalKm,
                      baseEarnings: earningsState.baseEarnings,
                      bonusEarnings: earningsState.bonusEarnings,
                    ),
                    const SizedBox(height: 20),

                    // Daily chart
                    _buildChartSection(earningsState),
                    const SizedBox(height: 20),

                    // Stats grid
                    _buildStatsGrid(earningsState),
                    const SizedBox(height: 20),

                    // Performance card
                    _buildPerformanceCard(earningsState),
                    const SizedBox(height: 20),

                    // Payout status
                    _buildPayoutStatus(context, earningsState),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodTabs(
    EarningsScreenState state,
    EarningsNotifier notifier,
  ) {
    return Container(
      color: DeliveryColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: EarningsPeriod.values.map((period) {
          final isSelected = state.period == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periodLabel(period)),
              selected: isSelected,
              onSelected: (_) => notifier.setPeriod(period),
              selectedColor: DeliveryColors.primary,
              backgroundColor: DeliveryColors.background,
              labelStyle: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : DeliveryColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? DeliveryColors.primary
                      : DeliveryColors.divider,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(EarningsScreenState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily Earnings',
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: DeliveryColors.earningsTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Base',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: DeliveryColors.bonusGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bonus',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          DailyChart(
            dailyEarnings: state.dailyEarnings,
            bonusPortionPercent: state.totalEarnings > 0
                ? (state.bonusEarnings / state.totalEarnings).clamp(0.0, 0.5)
                : 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(EarningsScreenState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatTile(
            icon: Icons.payments_outlined,
            label: 'Avg/delivery',
            value: CurrencyUtil.format(state.avgPerDelivery),
          ),
          _StatTile(
            icon: Icons.route,
            label: 'Avg km',
            value: '${state.avgKmPerDelivery.toStringAsFixed(1)} km',
          ),
          _StatTile(
            icon: Icons.schedule,
            label: 'Online hrs',
            value: state.onlineHours.toStringAsFixed(1),
          ),
          _StatTile(
            icon: Icons.speed,
            label: '\u20B9/hour',
            value: CurrencyUtil.format(state.earningsPerHour),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(EarningsScreenState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Rating
          Row(
            children: [
              Icon(Icons.star, color: DeliveryColors.bonusGold, size: 20),
              const SizedBox(width: 6),
              Text(
                state.rating.toStringAsFixed(1),
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (state.rating / 5).clamp(0.0, 1.0),
                    backgroundColor: DeliveryColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      DeliveryColors.bonusGold,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Top agents earn 20% bonus for \u26054.5+',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: DeliveryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Acceptance rate
          Row(
            children: [
              Icon(
                Icons.thumb_up_outlined,
                color: DeliveryColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.acceptanceRate.toStringAsFixed(0)}%',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Acceptance rate',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (state.acceptanceRate / 100).clamp(0.0, 1.0),
                    backgroundColor: DeliveryColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      DeliveryColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutStatus(BuildContext context, EarningsScreenState state) {
    // Compute next Monday for expected payout
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = daysUntilMonday == 0
        ? now.add(const Duration(days: 7))
        : now.add(Duration(days: daysUntilMonday));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout Status',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: DeliveryColors.earningsTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "This week's payout: ",
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              Text(
                CurrencyUtil.format(state.weeklyPayout),
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.earningsTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Expected: Monday ${DateUtil.formatDate(nextMonday)}',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: DeliveryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/earnings/payouts'),
            child: Text(
              'View payout history',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: DeliveryColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.week:
        return 'Week';
      case EarningsPeriod.month:
        return 'Month';
    }
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: DeliveryColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: DeliveryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
