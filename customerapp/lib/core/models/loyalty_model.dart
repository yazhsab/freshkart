class LoyaltyModel {
  final int totalEarned;
  final int totalRedeemed;
  final int currentBalance;
  final List<LoyaltyTransactionModel> recentTransactions;

  LoyaltyModel({
    required this.totalEarned,
    required this.totalRedeemed,
    required this.currentBalance,
    this.recentTransactions = const [],
  });

  factory LoyaltyModel.fromJson(Map<String, dynamic> json) => LoyaltyModel(
    totalEarned: json['total_earned'] ?? 0,
    totalRedeemed: json['total_redeemed'] ?? 0,
    currentBalance: json['current_balance'] ?? 0,
    recentTransactions: (json['recent_transactions'] as List?)
        ?.map((e) => LoyaltyTransactionModel.fromJson(e))
        .toList() ?? [],
  );
}

class LoyaltyTransactionModel {
  final String id;
  final String type;
  final int points;
  final int balanceAfter;
  final String? referenceType;
  final String? description;
  final DateTime createdAt;

  LoyaltyTransactionModel({
    required this.id,
    required this.type,
    required this.points,
    required this.balanceAfter,
    this.referenceType,
    this.description,
    required this.createdAt,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) => LoyaltyTransactionModel(
    id: json['id'],
    type: json['type'],
    points: json['points'],
    balanceAfter: json['balance_after'],
    referenceType: json['reference_type'],
    description: json['description'],
    createdAt: DateTime.parse(json['created_at']),
  );

  bool get isEarn => type == 'earn' || type == 'bonus';
}
