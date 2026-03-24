import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/config/app_config.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';

class DeliveryCompleteScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryCompleteScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryCompleteScreen> createState() =>
      _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState
    extends ConsumerState<DeliveryCompleteScreen> {
  int _countdown = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _navigateHome();
      }
    });
  }

  void _navigateHome() {
    if (mounted) {
      context.go('/');
    }
  }

  void _goOfflineAndHome() {
    LocalStorage.setIsOnline(false);
    _countdownTimer?.cancel();
    _navigateHome();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final order = deliveryState.order;

    final deliveryFee = order?.deliveryFee ?? DeliveryAppConfig.baseDeliveryFee;
    final isPeakHour = DeliveryAppConfig.isPeakHour();
    final peakBonus = isPeakHour ? DeliveryAppConfig.peakHourBonus : 0.0;
    final totalEarning = deliveryFee + peakBonus;

    // Mock today's stats (in production, from API)
    const todayDeliveries = 5;
    const todayEarnings = 180.0;
    const dailyTarget = 500.0;
    const rating = 4.7;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            // Top gradient section
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DeliveryColors.primary,
                      DeliveryColors.primaryLight,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Checkmark
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Delivery Complete!',
                        style: GoogleFonts.notoSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (order != null)
                        Text(
                          'Order #${order.orderNumber} delivered successfully',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom section
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Earnings card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DeliveryColors.earningsTeal.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DeliveryColors.earningsTeal.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'You earned',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: DeliveryColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyUtil.format(totalEarning),
                            style: GoogleFonts.notoSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: DeliveryColors.bonusGold,
                            ),
                          ),
                          if (isPeakHour) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DeliveryColors.bonusGold.withOpacity(
                                  0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+${CurrencyUtil.format(peakBonus)} peak hour bonus',
                                style: GoogleFonts.notoSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DeliveryColors.bonusGold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Today's summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DeliveryColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DeliveryColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Summary",
                            style: GoogleFonts.notoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DeliveryColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _SummaryItem(
                                icon: Icons.local_shipping_outlined,
                                value: '$todayDeliveries',
                                label: 'Deliveries',
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: DeliveryColors.divider,
                              ),
                              _SummaryItem(
                                icon: Icons.account_balance_wallet_outlined,
                                value: CurrencyUtil.format(
                                  todayEarnings + totalEarning,
                                ),
                                label: 'Total earned',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Progress bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${CurrencyUtil.format(todayEarnings + totalEarning)} of ${CurrencyUtil.format(dailyTarget)} daily target',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: DeliveryColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${(((todayEarnings + totalEarning) / dailyTarget) * 100).toInt()}%',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DeliveryColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  ((todayEarnings + totalEarning) / dailyTarget)
                                      .clamp(0.0, 1.0),
                              backgroundColor: DeliveryColors.divider,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                DeliveryColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rating
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DeliveryColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DeliveryColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: DeliveryColors.bonusGold,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your rating: $rating',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: DeliveryColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Maintain 4.5+ for bonus',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    color: DeliveryColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          _navigateHome();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DeliveryColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue Deliveries',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _goOfflineAndHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DeliveryColors.primary,
                          side: const BorderSide(
                            color: DeliveryColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Take a break',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Countdown text
                    Text(
                      _countdown > 0
                          ? 'Returning to home in $_countdown seconds...'
                          : 'Redirecting...',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: DeliveryColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DeliveryColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: DeliveryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
