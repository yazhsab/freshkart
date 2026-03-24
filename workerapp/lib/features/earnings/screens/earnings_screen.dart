import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/features/earnings/providers/earnings_provider.dart';
import 'package:freshkart_worker/features/earnings/widgets/earnings_chart.dart';
import 'package:freshkart_worker/shared/widgets/shimmer_loader.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EarningsPeriod _period = EarningsPeriod.today;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _period = EarningsPeriod.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(earningsProvider(_period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.pushNamed('payout-history'),
            child: const Text('Payouts'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: WorkerColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: WorkerColors.primary,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: earningsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerLoader.list(),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (earnings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    WorkerColors.earningsGreen,
                    WorkerColors.earningsGreen.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Net Earnings',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyUtil.format(earnings.netEarnings),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('Jobs', '${earnings.totalJobs}'),
                      _miniStat(
                        'Gross',
                        CurrencyUtil.compact(earnings.grossEarnings),
                      ),
                      _miniStat(
                        'Avg/Job',
                        CurrencyUtil.compact(earnings.avgPerJob),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (earnings.dailyEarnings.isNotEmpty) ...[
              const Text(
                'Daily Earnings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: EarningsChart(dailyEarnings: earnings.dailyEarnings),
              ),
              const SizedBox(height: 20),
            ],
            if (earnings.topServices.isNotEmpty) ...[
              const Text(
                'Top Services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...earnings.topServices.map((s) {
                final maxRevenue = earnings.topServices.first.revenue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.serviceName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${s.count} jobs • ${CurrencyUtil.format(s.revenue)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: maxRevenue > 0 ? s.revenue / maxRevenue : 0,
                          backgroundColor: Colors.grey.shade200,
                          color: WorkerColors.primary,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
