import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/profile/providers/profile_provider.dart';

class BankDetailsScreen extends ConsumerWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bank Details')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (worker) {
          if (worker == null) return const Center(child: Text('Not found'));
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 40,
                        color: WorkerColors.primary,
                      ),
                      const SizedBox(height: 16),
                      _row('Bank', worker.bankName ?? 'N/A'),
                      _row('Account', worker.maskedBankAccount),
                      _row('IFSC', worker.bankIfsc ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'To change bank details, please contact support for security verification.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
