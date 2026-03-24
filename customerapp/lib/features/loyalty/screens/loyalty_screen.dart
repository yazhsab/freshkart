import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/loyalty/providers/loyalty_provider.dart';
import 'package:intl/intl.dart';

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).fetchLoyalty();
      ref.read(loyaltyProvider.notifier).fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Points')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(loyaltyProvider.notifier).fetchLoyalty();
                await ref.read(loyaltyProvider.notifier).fetchTransactions();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Points Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.orange.shade800],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${state.loyalty?.currentBalance ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const Text('Points Available', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _PointsStat('Earned', '${state.loyalty?.totalEarned ?? 0}'),
                            Container(height: 30, width: 1, color: Colors.white30),
                            _PointsStat('Redeemed', '${state.loyalty?.totalRedeemed ?? 0}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Earn 1 point for every ₹100 spent. 1 point = ₹1 discount.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Points History',
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
                        backgroundColor: txn.isEarn ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(
                          txn.isEarn ? Icons.add : Icons.remove,
                          color: txn.isEarn ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(txn.description ?? txn.type),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(txn.createdAt)),
                      trailing: Text(
                        '${txn.isEarn ? '+' : '-'}${txn.points.abs()} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: txn.isEarn ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}

class _PointsStat extends StatelessWidget {
  final String label;
  final String value;
  const _PointsStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}
