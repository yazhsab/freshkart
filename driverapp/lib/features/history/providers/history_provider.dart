import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';

enum DateFilter { today, week, month }

class HistoryState {
  final List<DeliveryOrderModel> deliveries;
  final DateFilter dateFilter;
  final bool isLoading;
  final int page;
  final bool hasMore;
  final String? error;
  final int totalCount;
  final double totalEarnings;
  final double totalKm;

  const HistoryState({
    this.deliveries = const [],
    this.dateFilter = DateFilter.today,
    this.isLoading = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
    this.totalCount = 0,
    this.totalEarnings = 0.0,
    this.totalKm = 0.0,
  });

  HistoryState copyWith({
    List<DeliveryOrderModel>? deliveries,
    DateFilter? dateFilter,
    bool? isLoading,
    int? page,
    bool? hasMore,
    String? error,
    int? totalCount,
    double? totalEarnings,
    double? totalKm,
  }) {
    return HistoryState(
      deliveries: deliveries ?? this.deliveries,
      dateFilter: dateFilter ?? this.dateFilter,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalKm: totalKm ?? this.totalKm,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState()) {
    fetchDeliveries();
  }

  final ApiClient _api = ApiClient.instance;

  DateTime _getDateFrom(DateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case DateFilter.month:
        return DateTime(now.year, now.month, 1);
    }
  }

  Future<void> fetchDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dateFrom = _getDateFrom(state.dateFilter);
      final response = await _api.get(
        ApiEndpoints.deliveryHistory,
        queryParameters: {
          'date_from': dateFrom.toIso8601String(),
          'page': state.page,
          'limit': 20,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items =
          (data['deliveries'] as List<dynamic>?)
              ?.map(
                (e) => DeliveryOrderModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      final totalCount = (data['total_count'] as num?)?.toInt() ?? items.length;
      final totalEarnings = (data['total_earnings'] as num?)?.toDouble() ?? 0.0;
      final totalKm = (data['total_km'] as num?)?.toDouble() ?? 0.0;

      if (state.page == 1) {
        state = state.copyWith(
          deliveries: items,
          isLoading: false,
          hasMore: items.length >= 20,
          totalCount: totalCount,
          totalEarnings: totalEarnings,
          totalKm: totalKm,
        );
      } else {
        state = state.copyWith(
          deliveries: [...state.deliveries, ...items],
          isLoading: false,
          hasMore: items.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(page: state.page + 1);
    await fetchDeliveries();
  }

  Future<void> setDateFilter(DateFilter filter) async {
    if (state.dateFilter == filter) return;
    state = state.copyWith(
      dateFilter: filter,
      page: 1,
      deliveries: [],
      hasMore: true,
    );
    await fetchDeliveries();
  }

  Future<void> refresh() async {
    state = state.copyWith(page: 1, hasMore: true);
    await fetchDeliveries();
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  return HistoryNotifier();
});
