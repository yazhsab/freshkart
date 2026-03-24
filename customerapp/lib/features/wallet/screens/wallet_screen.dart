import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/wallet/providers/wallet_provider.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWallet();
      ref.read(walletProvider.notifier).fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(walletProvider.notifier).fetchWallet();
                await ref.read(walletProvider.notifier).fetchTransactions();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wallet Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '₹${state.wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showTopupDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryGreen,
                            ),
                            child: const Text('Top Up'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Transaction History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (state.transactions.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No transactions yet', style: TextStyle(color: Colors.grey)),
                    )),
                  ...state.transactions.map((txn) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: txn.isCredit
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: Icon(
                          txn.isCredit ? Icons.add : Icons.remove,
                          color: txn.isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(txn.description ?? txn.referenceType ?? txn.type),
                      subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(txn.createdAt)),
                      trailing: Text(
                        '${txn.isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: txn.isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
    );
  }

  void _showTopupDialog(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Top Up Wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [100, 200, 500, 1000].map((amt) => ActionChip(
                label: Text('₹$amt'),
                onPressed: () => controller.text = amt.toString(),
              )).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(ctx);
                  ref.read(walletProvider.notifier).initiateTopup(amount);
                }
              },
              child: const Text('Proceed to Pay'),
            ),
          ],
        ),
      ),
    );
  }
}
