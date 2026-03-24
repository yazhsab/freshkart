import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/loyalty_model.dart';

class LoyaltyState {
  final bool isLoading;
  final LoyaltyModel? loyalty;
  final List<LoyaltyTransactionModel> transactions;
  final String? error;

  LoyaltyState({this.isLoading = false, this.loyalty, this.transactions = const [], this.error});

  LoyaltyState copyWith({bool? isLoading, LoyaltyModel? loyalty, List<LoyaltyTransactionModel>? transactions, String? error}) =>
    LoyaltyState(
      isLoading: isLoading ?? this.isLoading,
      loyalty: loyalty ?? this.loyalty,
      transactions: transactions ?? this.transactions,
      error: error,
    );
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier() : super(LoyaltyState());

  final _api = ApiClient.instance;

  Future<void> fetchLoyalty() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/api/v1/loyalty');
      final loyalty = LoyaltyModel.fromJson(response.data['data']);
      state = state.copyWith(isLoading: false, loyalty: loyalty);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTransactions({int page = 1}) async {
    try {
      final response = await _api.get('/api/v1/loyalty/transactions?page=$page&limit=20');
      final list = (response.data['data'] as List)
          .map((e) => LoyaltyTransactionModel.fromJson(e))
          .toList();
      state = state.copyWith(transactions: page == 1 ? list : [...state.transactions, ...list]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>(
  (ref) => LoyaltyNotifier(),
);
