import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/models/earnings_model.dart';
import 'package:freshkart_delivery/core/models/payout_model.dart';

enum EarningsPeriod { today, week, month }

class EarningsScreenState {
  final EarningsPeriod period;
  final double totalEarnings;
  final int deliveryCount;
  final double totalKm;
  final double avgPerDelivery;
  final double avgKmPerDelivery;
  final double onlineHours;
  final double earningsPerHour;
  final List<DailyEarnings> dailyEarnings;
  final double baseEarnings;
  final double bonusEarnings;
  final double rating;
  final double acceptanceRate;
  final double weeklyPayout;
  final DateTime? payoutDate;
  final bool isLoading;
  final String? error;

  const EarningsScreenState({
    this.period = EarningsPeriod.today,
    this.totalEarnings = 0.0,
    this.deliveryCount = 0,
    this.totalKm = 0.0,
    this.avgPerDelivery = 0.0,
    this.avgKmPerDelivery = 0.0,
    this.onlineHours = 0.0,
    this.earningsPerHour = 0.0,
    this.dailyEarnings = const [],
    this.baseEarnings = 0.0,
    this.bonusEarnings = 0.0,
    this.rating = 0.0,
    this.acceptanceRate = 0.0,
    this.weeklyPayout = 0.0,
    this.payoutDate,
    this.isLoading = false,
    this.error,
  });

  EarningsScreenState copyWith({
    EarningsPeriod? period,
    double? totalEarnings,
    int? deliveryCount,
    double? totalKm,
    double? avgPerDelivery,
    double? avgKmPerDelivery,
    double? onlineHours,
    double? earningsPerHour,
    List<DailyEarnings>? dailyEarnings,
    double? baseEarnings,
    double? bonusEarnings,
    double? rating,
    double? acceptanceRate,
    double? weeklyPayout,
    DateTime? payoutDate,
    bool? isLoading,
    String? error,
  }) {
    return EarningsScreenState(
      period: period ?? this.period,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      deliveryCount: deliveryCount ?? this.deliveryCount,
      totalKm: totalKm ?? this.totalKm,
      avgPerDelivery: avgPerDelivery ?? this.avgPerDelivery,
      avgKmPerDelivery: avgKmPerDelivery ?? this.avgKmPerDelivery,
      onlineHours: onlineHours ?? this.onlineHours,
      earningsPerHour: earningsPerHour ?? this.earningsPerHour,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      baseEarnings: baseEarnings ?? this.baseEarnings,
      bonusEarnings: bonusEarnings ?? this.bonusEarnings,
      rating: rating ?? this.rating,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      weeklyPayout: weeklyPayout ?? this.weeklyPayout,
      payoutDate: payoutDate ?? this.payoutDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EarningsNotifier extends StateNotifier<EarningsScreenState> {
  EarningsNotifier() : super(const EarningsScreenState()) {
    fetchEarnings(EarningsPeriod.today);
  }

  final ApiClient _api = ApiClient.instance;

  String _periodString(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.today:
        return 'today';
      case EarningsPeriod.week:
        return 'week';
      case EarningsPeriod.month:
        return 'month';
    }
  }

  Future<void> fetchEarnings(EarningsPeriod period) async {
    state = state.copyWith(isLoading: true, error: null, period: period);

    try {
      final response = await _api.get(
        ApiEndpoints.earnings,
        queryParameters: {'period': _periodString(period)},
      );

      final data = response.data as Map<String, dynamic>;
      final earningsData = data['earnings'] as Map<String, dynamic>? ?? data;

      final model = EarningsModel.fromJson(earningsData);

      final deliveryCount = model.deliveryCount;
      final totalKm = model.totalDistanceKm;
      final avgPerDelivery = deliveryCount > 0
          ? model.totalEarnings / deliveryCount
          : 0.0;
      final avgKmPerDelivery = deliveryCount > 0
          ? totalKm / deliveryCount
          : 0.0;
      final onlineHours =
          (earningsData['online_hours'] as num?)?.toDouble() ?? 0.0;
      final earningsPerHour = onlineHours > 0
          ? model.totalEarnings / onlineHours
          : 0.0;
      final baseEarnings = model.deliveryFees;
      final bonusEarnings = model.bonuses + model.tips;
      final rating = (earningsData['rating'] as num?)?.toDouble() ?? 0.0;
      final acceptanceRate =
          (earningsData['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
      final weeklyPayout =
          (earningsData['weekly_payout'] as num?)?.toDouble() ?? 0.0;
      final payoutDateStr = earningsData['payout_date'] as String?;
      final payoutDate = payoutDateStr != null
          ? DateTime.tryParse(payoutDateStr)
          : null;

      state = state.copyWith(
        totalEarnings: model.totalEarnings,
        deliveryCount: deliveryCount,
        totalKm: totalKm,
        avgPerDelivery: avgPerDelivery,
        avgKmPerDelivery: avgKmPerDelivery,
        onlineHours: onlineHours,
        earningsPerHour: earningsPerHour,
        dailyEarnings: model.dailyEarnings,
        baseEarnings: baseEarnings,
        bonusEarnings: bonusEarnings,
        rating: rating,
        acceptanceRate: acceptanceRate,
        weeklyPayout: weeklyPayout,
        payoutDate: payoutDate,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setPeriod(EarningsPeriod period) async {
    if (state.period == period) return;
    await fetchEarnings(period);
  }
}

final earningsProvider =
    StateNotifierProvider<EarningsNotifier, EarningsScreenState>((ref) {
      return EarningsNotifier();
    });

final payoutsProvider = FutureProvider<List<PayoutModel>>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.payouts);
  final data = response.data as Map<String, dynamic>;
  final items =
      (data['payouts'] as List<dynamic>?)
          ?.map((e) => PayoutModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [];
  return items;
});
