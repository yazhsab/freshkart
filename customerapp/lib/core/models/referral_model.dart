class ReferralCodeModel {
  final String id;
  final String userId;
  final String code;
  final int totalReferrals;
  final double totalEarned;
  final bool isActive;

  ReferralCodeModel({
    required this.id,
    required this.userId,
    required this.code,
    this.totalReferrals = 0,
    this.totalEarned = 0,
    this.isActive = true,
  });

  factory ReferralCodeModel.fromJson(Map<String, dynamic> json) => ReferralCodeModel(
    id: json['id'],
    userId: json['user_id'],
    code: json['code'],
    totalReferrals: json['total_referrals'] ?? 0,
    totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
    isActive: json['is_active'] ?? true,
  );
}

class ReferralStatsModel {
  final String? code;
  final int totalReferrals;
  final double totalEarned;
  final List<ReferralModel> referrals;

  ReferralStatsModel({
    this.code,
    this.totalReferrals = 0,
    this.totalEarned = 0,
    this.referrals = const [],
  });

  factory ReferralStatsModel.fromJson(Map<String, dynamic> json) => ReferralStatsModel(
    code: json['code'],
    totalReferrals: json['total_referrals'] ?? 0,
    totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
    referrals: (json['referrals'] as List?)
        ?.map((e) => ReferralModel.fromJson(e))
        .toList() ?? [],
  );
}

class ReferralModel {
  final String id;
  final String referrerId;
  final String refereeId;
  final String status;
  final double? referrerReward;
  final double? refereeReward;
  final String? refereeName;
  final DateTime createdAt;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.status,
    this.referrerReward,
    this.refereeReward,
    this.refereeName,
    required this.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
    id: json['id'],
    referrerId: json['referrer_id'],
    refereeId: json['referee_id'],
    status: json['status'],
    referrerReward: (json['referrer_reward'] as num?)?.toDouble(),
    refereeReward: (json['referee_reward'] as num?)?.toDouble(),
    refereeName: json['profiles']?['full_name'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
