class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final DateTime createdAt;
  final List<WalletTransactionModel> recentTransactions;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    this.recentTransactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'],
    userId: json['user_id'],
    balance: (json['balance'] as num).toDouble(),
    createdAt: DateTime.parse(json['created_at']),
    recentTransactions: (json['recent_transactions'] as List?)
        ?.map((e) => WalletTransactionModel.fromJson(e))
        .toList() ?? [],
  );
}

class WalletTransactionModel {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) => WalletTransactionModel(
    id: json['id'],
    type: json['type'],
    amount: (json['amount'] as num).toDouble(),
    balanceAfter: (json['balance_after'] as num).toDouble(),
    referenceType: json['reference_type'],
    referenceId: json['reference_id'],
    description: json['description'],
    createdAt: DateTime.parse(json['created_at']),
  );

  bool get isCredit => type == 'credit';
}
