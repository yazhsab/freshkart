import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/referral_model.dart';

class ReferralState {
  final bool isLoading;
  final ReferralStatsModel? stats;
  final String? error;

  ReferralState({this.isLoading = false, this.stats, this.error});

  ReferralState copyWith({bool? isLoading, ReferralStatsModel? stats, String? error}) =>
    ReferralState(isLoading: isLoading ?? this.isLoading, stats: stats ?? this.stats, error: error);
}

class ReferralNotifier extends StateNotifier<ReferralState> {
  ReferralNotifier() : super(ReferralState());

  final _api = ApiClient.instance;

  Future<void> fetchReferralCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // This also generates the code if not exists
      await _api.get('/api/v1/referral/code');
      await fetchStats();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await _api.get('/api/v1/referral/stats');
      final stats = ReferralStatsModel.fromJson(response.data['data']);
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> applyReferralCode(String code) async {
    try {
      await _api.post('/api/v1/referral/apply', data: {'code': code});
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final referralProvider = StateNotifierProvider<ReferralNotifier, ReferralState>(
  (ref) => ReferralNotifier(),
);
