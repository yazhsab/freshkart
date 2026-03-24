import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── State ────────────────────────────────────────────────────────

class WalletListState {
  const WalletListState({
    this.wallets = const [],
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<WalletRow> wallets;
  final String searchQuery;
  final bool isLoading;

  WalletListState copyWith({
    List<WalletRow>? wallets,
    String? searchQuery,
    bool? isLoading,
  }) {
    return WalletListState(
      wallets: wallets ?? this.wallets,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<WalletRow> get filteredWallets {
    if (searchQuery.isEmpty) return wallets;
    final q = searchQuery.toLowerCase();
    return wallets.where((w) {
      return w.userName.toLowerCase().contains(q) ||
          (w.userPhone?.contains(q) ?? false) ||
          (w.userEmail?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

// ── Wallet row model ─────────────────────────────────────────────

class WalletRow {
  const WalletRow({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userEmail,
    this.balance = 0,
    this.lastTransactionAt,
    this.lastTransactionType,
    this.lastTransactionAmount,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userEmail;
  final double balance;
  final DateTime? lastTransactionAt;
  final String? lastTransactionType;
  final double? lastTransactionAmount;

  factory WalletRow.fromMap(Map<String, dynamic> m) {
    final profile = m['profiles'] as Map<String, dynamic>?;
    return WalletRow(
      id: m['id'] as String,
      userId: m['user_id'] as String? ?? '',
      userName: profile?['full_name'] as String? ?? 'Unknown',
      userPhone: profile?['phone'] as String?,
      userEmail: profile?['email'] as String?,
      balance: ((m['balance'] as num?) ?? 0).toDouble(),
      lastTransactionAt: m['last_transaction_at'] != null
          ? DateTime.tryParse(m['last_transaction_at'].toString())
          : null,
      lastTransactionType: m['last_transaction_type'] as String?,
      lastTransactionAmount:
          (m['last_transaction_amount'] as num?)?.toDouble(),
    );
  }
}

// ── Wallet transaction model ─────────────────────────────────────

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.description,
    this.createdAt,
  });

  final String id;
  final String walletId;
  final String type; // credit / debit
  final double amount;
  final String? description;
  final DateTime? createdAt;

  factory WalletTransaction.fromMap(Map<String, dynamic> m) {
    return WalletTransaction(
      id: m['id'] as String,
      walletId: m['wallet_id'] as String? ?? '',
      type: m['type'] as String? ?? 'credit',
      amount: ((m['amount'] as num?) ?? 0).toDouble(),
      description: m['description'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────

final walletListProvider =
    NotifierProvider<WalletListNotifier, WalletListState>(
  WalletListNotifier.new,
);

class WalletListNotifier extends Notifier<WalletListState> {
  @override
  WalletListState build() {
    fetchWallets();
    return const WalletListState(isLoading: true);
  }

  Future<void> fetchWallets() async {
    state = state.copyWith(isLoading: true);
    try {
      final rows = await adminClient
          .from('wallets')
          .select(
            '*, profiles!wallets_user_id_fkey(id, full_name, phone, email)',
          )
          .order('balance', ascending: false);

      final wallets = (rows as List)
          .map((row) => WalletRow.fromMap(row as Map<String, dynamic>))
          .toList();

      state = state.copyWith(wallets: wallets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> creditWallet(
      String userId, double amount, String description) async {
    await adminClient.rpc('admin_wallet_credit', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_description': description,
    });
    await fetchWallets();
  }

  Future<void> debitWallet(
      String userId, double amount, String description) async {
    await adminClient.rpc('admin_wallet_debit', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_description': description,
    });
    await fetchWallets();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

// ── Transaction history provider ─────────────────────────────────

final walletTransactionsProvider =
    FutureProvider.family<List<WalletTransaction>, String>(
  (ref, walletId) async {
    final rows = await adminClient
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((row) =>
            WalletTransaction.fromMap(row as Map<String, dynamic>))
        .toList();
  },
);
