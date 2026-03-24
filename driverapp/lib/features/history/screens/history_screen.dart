import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/features/shared/widgets/empty_state_widget.dart';
import 'package:freshkart_delivery/features/history/providers/history_provider.dart';
import 'package:freshkart_delivery/features/history/widgets/history_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Delivery History',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            color: DeliveryColors.textPrimary,
          ),
        ),
        backgroundColor: DeliveryColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Date filter chips
          Container(
            color: DeliveryColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: DateFilter.values.map((filter) {
                final isSelected = historyState.dateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: isSelected,
                    onSelected: (_) => notifier.setDateFilter(filter),
                    selectedColor: DeliveryColors.primary,
                    backgroundColor: DeliveryColors.background,
                    labelStyle: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : DeliveryColors.textPrimary,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Summary row
          if (historyState.deliveries.isNotEmpty)
            Container(
              color: DeliveryColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DeliveryColors.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      value: '${historyState.totalCount}',
                      label: 'deliveries',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: DeliveryColors.primary.withOpacity(0.2),
                    ),
                    _SummaryItem(
                      value: CurrencyUtil.format(historyState.totalEarnings),
                      label: 'earned',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: DeliveryColors.primary.withOpacity(0.2),
                    ),
                    _SummaryItem(
                      value: '${historyState.totalKm.toStringAsFixed(1)} km',
                      label: 'covered',
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: DeliveryColors.divider),

          // Delivery list
          Expanded(child: _buildBody(historyState, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(HistoryState historyState, HistoryNotifier notifier) {
    if (historyState.isLoading && historyState.deliveries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DeliveryColors.primary),
      );
    }

    if (historyState.error != null && historyState.deliveries.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: historyState.error,
        actionLabel: 'Retry',
        onAction: () => notifier.refresh(),
      );
    }

    if (historyState.deliveries.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.local_shipping_outlined,
        title: 'No deliveries yet',
        subtitle: 'Your completed deliveries will appear here.',
      );
    }

    return RefreshIndicator(
      color: DeliveryColors.primary,
      onRefresh: () => notifier.refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            notifier.loadNextPage();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount:
              historyState.deliveries.length + (historyState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= historyState.deliveries.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DeliveryColors.primary,
                    ),
                  ),
                ),
              );
            }
            return HistoryCard(delivery: historyState.deliveries[index]);
          },
        ),
      ),
    );
  }

  String _filterLabel(DateFilter filter) {
    switch (filter) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.week:
        return 'This Week';
      case DateFilter.month:
        return 'This Month';
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DeliveryColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 11,
            color: DeliveryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
