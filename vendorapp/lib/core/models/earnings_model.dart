class EarningsModel {
  final String period;
  final double grossRevenue;
  final double deliveryFeesCollected;
  final double platformCommission;
  final double netEarnings;
  final int orderCount;
  final double avgOrderValue;
  final int cancellationCount;
  final double cancellationRate;
  final List<DailyRevenue> dailyRevenue;
  final List<TopProduct> topProducts;

  const EarningsModel({
    required this.period,
    this.grossRevenue = 0.0,
    this.deliveryFeesCollected = 0.0,
    this.platformCommission = 0.0,
    this.netEarnings = 0.0,
    this.orderCount = 0,
    this.avgOrderValue = 0.0,
    this.cancellationCount = 0,
    this.cancellationRate = 0.0,
    this.dailyRevenue = const [],
    this.topProducts = const [],
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      period: json['period'] as String? ?? '',
      grossRevenue: (json['gross_revenue'] as num?)?.toDouble() ?? 0.0,
      deliveryFeesCollected:
          (json['delivery_fees_collected'] as num?)?.toDouble() ?? 0.0,
      platformCommission:
          (json['platform_commission'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (json['net_earnings'] as num?)?.toDouble() ?? 0.0,
      orderCount: json['order_count'] as int? ?? 0,
      avgOrderValue: (json['avg_order_value'] as num?)?.toDouble() ?? 0.0,
      cancellationCount: json['cancellation_count'] as int? ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
      dailyRevenue: json['daily_revenue'] != null
          ? (json['daily_revenue'] as List<dynamic>)
                .map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      topProducts: json['top_products'] != null
          ? (json['top_products'] as List<dynamic>)
                .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'gross_revenue': grossRevenue,
      'delivery_fees_collected': deliveryFeesCollected,
      'platform_commission': platformCommission,
      'net_earnings': netEarnings,
      'order_count': orderCount,
      'avg_order_value': avgOrderValue,
      'cancellation_count': cancellationCount,
      'cancellation_rate': cancellationRate,
      'daily_revenue': dailyRevenue.map((e) => e.toJson()).toList(),
      'top_products': topProducts.map((e) => e.toJson()).toList(),
    };
  }

  EarningsModel copyWith({
    String? period,
    double? grossRevenue,
    double? deliveryFeesCollected,
    double? platformCommission,
    double? netEarnings,
    int? orderCount,
    double? avgOrderValue,
    int? cancellationCount,
    double? cancellationRate,
    List<DailyRevenue>? dailyRevenue,
    List<TopProduct>? topProducts,
  }) {
    return EarningsModel(
      period: period ?? this.period,
      grossRevenue: grossRevenue ?? this.grossRevenue,
      deliveryFeesCollected:
          deliveryFeesCollected ?? this.deliveryFeesCollected,
      platformCommission: platformCommission ?? this.platformCommission,
      netEarnings: netEarnings ?? this.netEarnings,
      orderCount: orderCount ?? this.orderCount,
      avgOrderValue: avgOrderValue ?? this.avgOrderValue,
      cancellationCount: cancellationCount ?? this.cancellationCount,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      topProducts: topProducts ?? this.topProducts,
    );
  }
}

class DailyRevenue {
  final String date;
  final double amount;

  const DailyRevenue({required this.date, required this.amount});

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'amount': amount};
  }

  DailyRevenue copyWith({String? date, double? amount}) {
    return DailyRevenue(date: date ?? this.date, amount: amount ?? this.amount);
  }
}

class TopProduct {
  final String name;
  final int unitsSold;
  final double revenue;

  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] as String,
      unitsSold: json['units_sold'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'units_sold': unitsSold, 'revenue': revenue};
  }

  TopProduct copyWith({String? name, int? unitsSold, double? revenue}) {
    return TopProduct(
      name: name ?? this.name,
      unitsSold: unitsSold ?? this.unitsSold,
      revenue: revenue ?? this.revenue,
    );
  }
}
