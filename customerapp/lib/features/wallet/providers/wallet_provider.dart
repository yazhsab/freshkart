import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/wallet_model.dart';

class WalletState {
  final bool isLoading;
  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final String? error;

  WalletState({this.isLoading = false, this.wallet, this.transactions = const [], this.error});

  WalletState copyWith({bool? isLoading, WalletModel? wallet, List<WalletTransactionModel>? transactions, String? error}) =>
    WalletState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      error: error,
    );
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(WalletState());

  final _api = ApiClient.instance;

  Future<void> fetchWallet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/api/v1/wallet');
      final wallet = WalletModel.fromJson(response.data['data']);
      state = state.copyWith(isLoading: false, wallet: wallet);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTransactions({int page = 1}) async {
    try {
      final response = await _api.get('/api/v1/wallet/transactions?page=$page&limit=20');
      final list = (response.data['data'] as List)
          .map((e) => WalletTransactionModel.fromJson(e))
          .toList();
      state = state.copyWith(transactions: page == 1 ? list : [...state.transactions, ...list]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> initiateTopup(double amount) async {
    try {
      final response = await _api.post('/api/v1/wallet/topup', data: {'amount': amount});
      return response.data['data']['razorpay_order'];
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> verifyTopup(String orderId, String paymentId, String signature, double amount) async {
    try {
      await _api.post('/api/v1/wallet/topup/verify', data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        'amount': amount,
      });
      await fetchWallet();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(),
);
