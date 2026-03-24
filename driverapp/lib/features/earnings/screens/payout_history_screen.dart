import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/shared/widgets/empty_state_widget.dart';
import 'package:freshkart_delivery/features/earnings/providers/earnings_provider.dart';
import 'package:freshkart_delivery/features/earnings/widgets/payout_card.dart';

class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutsProvider);

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Payout History',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            color: DeliveryColors.textPrimary,
          ),
        ),
        backgroundColor: DeliveryColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: payoutsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DeliveryColors.primary),
        ),
        error: (error, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Failed to load payouts',
          subtitle: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(payoutsProvider),
        ),
        data: (payouts) {
          if (payouts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No payouts yet',
              subtitle:
                  'Your payout history will appear here once you complete deliveries.',
            );
          }

          return RefreshIndicator(
            color: DeliveryColors.primary,
            onRefresh: () async => ref.invalidate(payoutsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: payouts.length,
              itemBuilder: (context, index) {
                return PayoutCard(payout: payouts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
