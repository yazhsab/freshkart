class EarningsModel {
  final DateTime date;
  final int deliveryCount;
  final double totalEarnings;
  final double deliveryEarnings;
  final double bonusEarnings;
  final double totalKmCovered;
  final double onlineHours;
  final List<DailyEarnings> dailyEarnings;

  const EarningsModel({
    required this.date,
    this.deliveryCount = 0,
    this.totalEarnings = 0.0,
    this.deliveryEarnings = 0.0,
    this.bonusEarnings = 0.0,
    this.totalKmCovered = 0.0,
    this.onlineHours = 0.0,
    this.dailyEarnings = const [],
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      date: DateTime.parse(json['date'] as String),
      deliveryCount: (json['delivery_count'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      deliveryEarnings: (json['delivery_earnings'] as num?)?.toDouble() ?? 0.0,
      bonusEarnings: (json['bonus_earnings'] as num?)?.toDouble() ?? 0.0,
      totalKmCovered: (json['total_km_covered'] as num?)?.toDouble() ?? 0.0,
      onlineHours: (json['online_hours'] as num?)?.toDouble() ?? 0.0,
      dailyEarnings:
          (json['daily_earnings'] as List<dynamic>?)
              ?.map((e) => DailyEarnings.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get totalDistanceKm => totalKmCovered;
  double get deliveryFees => deliveryEarnings;
  double get bonuses => bonusEarnings;
  double get tips => 0.0;

  double get avgPerDelivery =>
      deliveryCount > 0 ? totalEarnings / deliveryCount : 0.0;

  double get avgPerKm =>
      totalKmCovered > 0 ? totalEarnings / totalKmCovered : 0.0;
}

class DailyEarnings {
  final String date;
  final double earnings;
  final int deliveryCount;

  const DailyEarnings({
    required this.date,
    required this.earnings,
    this.deliveryCount = 0,
  });

  factory DailyEarnings.fromJson(Map<String, dynamic> json) {
    return DailyEarnings(
      date: json['date'] as String,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      deliveryCount: (json['delivery_count'] as num?)?.toInt() ?? 0,
    );
  }
}
