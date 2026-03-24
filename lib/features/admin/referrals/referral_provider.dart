import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── Referral stats model ─────────────────────────────────────────

class ReferralStats {
  const ReferralStats({
    this.totalReferrals = 0,
    this.totalRewardsPaid = 0,
    this.activeReferralCodes = 0,
    this.pendingRewards = 0,
  });

  final int totalReferrals;
  final double totalRewardsPaid;
  final int activeReferralCodes;
  final double pendingRewards;
}

// ── Referral code row ────────────────────────────────────────────

class ReferralCodeRow {
  const ReferralCodeRow({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.code,
    this.totalReferrals = 0,
    this.totalEarned = 0,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final String code;
  final int totalReferrals;
  final double totalEarned;
  final bool isActive;
  final DateTime? createdAt;

  factory ReferralCodeRow.fromMap(Map<String, dynamic> m) {
    final profile = m['profiles'] as Map<String, dynamic>?;
    return ReferralCodeRow(
      id: m['id'] as String,
      userId: m['user_id'] as String? ?? '',
      userName: profile?['full_name'] as String? ?? 'Unknown',
      userPhone: profile?['phone'] as String?,
      code: m['code'] as String? ?? '',
      totalReferrals: m['total_referrals'] as int? ?? 0,
      totalEarned: ((m['total_earned'] as num?) ?? 0).toDouble(),
      isActive: m['is_active'] as bool? ?? true,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
    );
  }
}

// ── Individual referral row ──────────────────────────────────────

class ReferralRow {
  const ReferralRow({
    required this.id,
    required this.referrerName,
    this.referrerPhone,
    required this.refereeName,
    this.refereePhone,
    required this.status,
    this.referrerReward = 0,
    this.refereeReward = 0,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String referrerName;
  final String? referrerPhone;
  final String refereeName;
  final String? refereePhone;
  final String status; // pending, completed, expired
  final double referrerReward;
  final double refereeReward;
  final DateTime? createdAt;
  final DateTime? completedAt;

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  factory ReferralRow.fromMap(Map<String, dynamic> m) {
    final referrer = m['referrer'] as Map<String, dynamic>?;
    final referee = m['referee'] as Map<String, dynamic>?;
    return ReferralRow(
      id: m['id'] as String,
      referrerName: referrer?['full_name'] as String? ?? 'Unknown',
      referrerPhone: referrer?['phone'] as String?,
      refereeName: referee?['full_name'] as String? ?? 'Unknown',
      refereePhone: referee?['phone'] as String?,
      status: m['status'] as String? ?? 'pending',
      referrerReward: ((m['referrer_reward'] as num?) ?? 0).toDouble(),
      refereeReward: ((m['referee_reward'] as num?) ?? 0).toDouble(),
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
      completedAt: m['completed_at'] != null
          ? DateTime.tryParse(m['completed_at'].toString())
          : null,
    );
  }
}

// ── State ────────────────────────────────────────────────────────

class ReferralListState {
  const ReferralListState({
    this.stats = const ReferralStats(),
    this.codes = const [],
    this.referrals = const [],
    this.isLoading = false,
    this.activeTab = 0,
    this.searchQuery = '',
  });

  final ReferralStats stats;
  final List<ReferralCodeRow> codes;
  final List<ReferralRow> referrals;
  final bool isLoading;
  final int activeTab; // 0 = codes, 1 = referrals
  final String searchQuery;

  ReferralListState copyWith({
    ReferralStats? stats,
    List<ReferralCodeRow>? codes,
    List<ReferralRow>? referrals,
    bool? isLoading,
    int? activeTab,
    String? searchQuery,
  }) {
    return ReferralListState(
      stats: stats ?? this.stats,
      codes: codes ?? this.codes,
      referrals: referrals ?? this.referrals,
      isLoading: isLoading ?? this.isLoading,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<ReferralCodeRow> get filteredCodes {
    if (searchQuery.isEmpty) return codes;
    final q = searchQuery.toLowerCase();
    return codes.where((c) {
      return c.userName.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          (c.userPhone?.contains(q) ?? false);
    }).toList();
  }

  List<ReferralRow> get filteredReferrals {
    if (searchQuery.isEmpty) return referrals;
    final q = searchQuery.toLowerCase();
    return referrals.where((r) {
      return r.referrerName.toLowerCase().contains(q) ||
          r.refereeName.toLowerCase().contains(q) ||
          (r.referrerPhone?.contains(q) ?? false) ||
          (r.refereePhone?.contains(q) ?? false);
    }).toList();
  }
}

// ── Provider ─────────────────────────────────────────────────────

final referralListProvider =
    NotifierProvider<ReferralListNotifier, ReferralListState>(
  ReferralListNotifier.new,
);

class ReferralListNotifier extends Notifier<ReferralListState> {
  @override
  ReferralListState build() {
    _loadAll();
    return const ReferralListState(isLoading: true);
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([
        fetchReferralStats(),
        fetchReferralCodes(),
        fetchReferrals(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchReferralStats() async {
    final results = await Future.wait([
      adminClient.from('referrals').select('id'),
      adminClient
          .from('referrals')
          .select('referrer_reward')
          .eq('status', 'completed'),
      adminClient
          .from('referral_codes')
          .select('id')
          .eq('is_active', true),
    ]);

    final totalReferrals = (results[0] as List).length;
    final completedRows = results[1] as List;
    var totalRewardsPaid = 0.0;
    for (final r in completedRows) {
      totalRewardsPaid +=
          ((r['referrer_reward'] as num?) ?? 0).toDouble();
    }
    final activeCodesCount = (results[2] as List).length;

    state = state.copyWith(
      stats: ReferralStats(
        totalReferrals: totalReferrals,
        totalRewardsPaid: totalRewardsPaid,
        activeReferralCodes: activeCodesCount,
      ),
    );
  }

  Future<void> fetchReferralCodes() async {
    final rows = await adminClient
        .from('referral_codes')
        .select(
          '*, profiles!referral_codes_user_id_fkey(id, full_name, phone)',
        )
        .order('created_at', ascending: false);

    final codes = (rows as List)
        .map((row) =>
            ReferralCodeRow.fromMap(row as Map<String, dynamic>))
        .toList();

    state = state.copyWith(codes: codes);
  }

  Future<void> fetchReferrals() async {
    final rows = await adminClient
        .from('referrals')
        .select(
          '*, referrer:profiles!referrals_referrer_id_fkey(id, full_name, phone), '
          'referee:profiles!referrals_referee_id_fkey(id, full_name, phone)',
        )
        .order('created_at', ascending: false)
        .limit(200);

    final referrals = (rows as List)
        .map(
            (row) => ReferralRow.fromMap(row as Map<String, dynamic>))
        .toList();

    state = state.copyWith(referrals: referrals);
  }

  void setActiveTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
