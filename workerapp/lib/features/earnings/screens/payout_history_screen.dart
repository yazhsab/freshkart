import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_worker/features/earnings/providers/earnings_provider.dart';
import 'package:freshkart_worker/features/earnings/widgets/payout_card.dart';
import 'package:freshkart_worker/shared/widgets/empty_state_widget.dart';

class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payout History')),
      body: payoutsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payouts) {
          if (payouts.isEmpty)
            return const EmptyStateWidget(
              icon: Icons.payments,
              title: 'No payouts yet',
            );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payouts.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PayoutCard(payout: payouts[index]),
            ),
          );
        },
      ),
    );
  }
}
