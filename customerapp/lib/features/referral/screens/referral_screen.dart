import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/referral/providers/referral_provider.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(referralProvider.notifier).fetchReferralCode());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, Colors.teal.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      const Text('Refer Friends & Earn',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Share your code with friends. You earn ₹50 and they get ₹25 when they place their first order!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      // Referral code
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white54, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.stats?.code ?? '...',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                if (state.stats?.code != null) {
                                  Clipboard.setData(ClipboardData(text: state.stats!.code!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code copied!')),
                                  );
                                }
                              },
                              child: const Icon(Icons.copy, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (state.stats?.code != null) {
                              Share.share(
                                'Join FreshKart using my code ${state.stats!.code} and get ₹25 wallet bonus! Download: https://freshkart.app',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryGreen,
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text('Share with Friends'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Stats
                Row(
                  children: [
                    Expanded(child: _StatCard('Total Referrals', '${state.stats?.totalReferrals ?? 0}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard('Total Earned', '₹${state.stats?.totalEarned?.toStringAsFixed(0) ?? '0'}')),
                  ],
                ),
                const SizedBox(height: 24),
                if (state.stats?.referrals.isNotEmpty ?? false) ...[
                  const Text('Your Referrals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...state.stats!.referrals.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(r.refereeName ?? 'Friend'),
                      subtitle: Text(r.status == 'rewarded' ? 'Completed' : 'Pending'),
                      trailing: r.status == 'rewarded'
                          ? Text('+₹${r.referrerReward?.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
                          : const Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
                    ),
                  )),
                ],
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    ),
  );
}
