import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── Loyalty stats model ──────────────────────────────────────────

class LoyaltyStats {
  const LoyaltyStats({
    this.totalPointsEarned = 0,
    this.totalPointsRedeemed = 0,
    this.pointsPer100 = 10,
    this.pointValue = 0.25,
    this.minRedeem = 100,
  });

  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final int pointsPer100; // points earned per 100 rupees spent
  final double pointValue; // INR value per point
  final int minRedeem; // minimum points to redeem

  int get totalOutstanding => totalPointsEarned - totalPointsRedeemed;
}

// ── User loyalty row ─────────────────────────────────────────────

class LoyaltyUserRow {
  const LoyaltyUserRow({
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userEmail,
    this.pointsBalance = 0,
    this.totalEarned = 0,
    this.totalRedeemed = 0,
    this.lastEarnedAt,
  });

  final String userId;
  final String userName;
  final String? userPhone;
  final String? userEmail;
  final int pointsBalance;
  final int totalEarned;
  final int totalRedeemed;
  final DateTime? lastEarnedAt;

  factory LoyaltyUserRow.fromMap(Map<String, dynamic> m) {
    final profile = m['profiles'] as Map<String, dynamic>?;
    return LoyaltyUserRow(
      userId: m['user_id'] as String? ?? '',
      userName: profile?['full_name'] as String? ?? 'Unknown',
      userPhone: profile?['phone'] as String?,
      userEmail: profile?['email'] as String?,
      pointsBalance: m['points_balance'] as int? ?? 0,
      totalEarned: m['total_earned'] as int? ?? 0,
      totalRedeemed: m['total_redeemed'] as int? ?? 0,
      lastEarnedAt: m['last_earned_at'] != null
          ? DateTime.tryParse(m['last_earned_at'].toString())
          : null,
    );
  }
}

// ── State ────────────────────────────────────────────────────────

class LoyaltyState {
  const LoyaltyState({
    this.stats = const LoyaltyStats(),
    this.users = const [],
    this.isLoading = false,
    this.searchQuery = '',
  });

  final LoyaltyStats stats;
  final List<LoyaltyUserRow> users;
  final bool isLoading;
  final String searchQuery;

  LoyaltyState copyWith({
    LoyaltyStats? stats,
    List<LoyaltyUserRow>? users,
    bool? isLoading,
    String? searchQuery,
  }) {
    return LoyaltyState(
      stats: stats ?? this.stats,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<LoyaltyUserRow> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    final q = searchQuery.toLowerCase();
    return users.where((u) {
      return u.userName.toLowerCase().contains(q) ||
          (u.userPhone?.contains(q) ?? false) ||
          (u.userEmail?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

// ── Provider ─────────────────────────────────────────────────────

final loyaltyProvider =
    NotifierProvider<LoyaltyNotifier, LoyaltyState>(
  LoyaltyNotifier.new,
);

class LoyaltyNotifier extends Notifier<LoyaltyState> {
  @override
  LoyaltyState build() {
    _loadAll();
    return const LoyaltyState(isLoading: true);
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([
        fetchLoyaltyStats(),
        _fetchUsers(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchLoyaltyStats() async {
    // Fetch config values
    final configRows = await adminClient
        .from('platform_config')
        .select()
        .inFilter('key', [
      'loyalty_points_per_100',
      'loyalty_point_value',
      'loyalty_min_redeem',
    ]);

    int pointsPer100 = 10;
    double pointValue = 0.25;
    int minRedeem = 100;

    for (final row in configRows) {
      final key = row['key'] as String;
      final val = row['value'] as String? ?? '';
      switch (key) {
        case 'loyalty_points_per_100':
          pointsPer100 = int.tryParse(val) ?? 10;
        case 'loyalty_point_value':
          pointValue = double.tryParse(val) ?? 0.25;
        case 'loyalty_min_redeem':
          minRedeem = int.tryParse(val) ?? 100;
      }
    }

    // Fetch aggregate stats
    final loyaltyRows = await adminClient
        .from('loyalty_accounts')
        .select('total_earned, total_redeemed');

    int totalEarned = 0;
    int totalRedeemed = 0;
    for (final r in loyaltyRows) {
      totalEarned += (r['total_earned'] as int? ?? 0);
      totalRedeemed += (r['total_redeemed'] as int? ?? 0);
    }

    state = state.copyWith(
      stats: LoyaltyStats(
        totalPointsEarned: totalEarned,
        totalPointsRedeemed: totalRedeemed,
        pointsPer100: pointsPer100,
        pointValue: pointValue,
        minRedeem: minRedeem,
      ),
    );
  }

  Future<void> _fetchUsers() async {
    final rows = await adminClient
        .from('loyalty_accounts')
        .select(
          '*, profiles!loyalty_accounts_user_id_fkey(id, full_name, phone, email)',
        )
        .order('points_balance', ascending: false);

    final users = (rows as List)
        .map((row) =>
            LoyaltyUserRow.fromMap(row as Map<String, dynamic>))
        .toList();

    state = state.copyWith(users: users);
  }

  Future<void> updateConfig(Map<String, String> changes) async {
    for (final entry in changes.entries) {
      await adminClient.from('platform_config').upsert({
        'key': entry.key,
        'value': entry.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    }
    await fetchLoyaltyStats();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
