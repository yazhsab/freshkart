import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/utils/currency_util.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';
import 'package:freshkart_delivery/features/delivery/providers/active_delivery_provider.dart';
import 'package:freshkart_delivery/features/delivery/widgets/otp_verify_card.dart';

class DeliveryOtpScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryOtpScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends ConsumerState<DeliveryOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _error;
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      setState(() => _error = 'Please enter the 4-digit OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final success = await ref
        .read(activeDeliveryProvider.notifier)
        .confirmDelivery(widget.orderId, otp);

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (success) {
      ref.read(deliveryProvider.notifier).setPhase(DeliveryPhase.completed);
      context.go('/delivery/${widget.orderId}/complete');
    } else {
      final activeError = ref.read(activeDeliveryProvider).error;
      setState(() {
        _error = activeError ?? 'Wrong OTP. Ask customer to check.';
      });
      _otpController.clear();
    }
  }

  void _showProblemSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer not available?',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _ProblemOption(
                icon: Icons.phone_outlined,
                title: 'Call customer',
                subtitle: 'Try reaching the customer by phone',
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              _ProblemOption(
                icon: Icons.timer_outlined,
                title: 'Wait at location',
                subtitle: 'Wait for 5 minutes before marking unavailable',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please wait at the location. Customer has been notified.',
                        style: GoogleFonts.notoSans(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _ProblemOption(
                icon: Icons.support_agent_outlined,
                title: 'Contact support',
                subtitle: 'Get help from our support team',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Support has been notified. They will call you shortly.',
                        style: GoogleFonts.notoSans(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final order = deliveryState.order;

    final isCod = order?.isCod ?? false;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DeliveryColors.surface,
        appBar: AppBar(
          backgroundColor: DeliveryColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Confirm Delivery',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DeliveryColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Text(
                  'Confirm delivery',
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                if (order != null) ...[
                  Text(
                    order.customerName,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customerArea,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // OTP Card with COD banner
                OtpVerifyCard(
                  title: 'Confirm Delivery',
                  subtitle: 'Ask customer for the 4-digit OTP',
                  tamilInstruction:
                      '\u0BB5\u0BBE\u0B9F\u0BBF\u0B95\u0BCD\u0B95\u0BC8\u0BAF\u0BBE\u0BB3\u0BB0\u0BBF\u0B9F\u0BAE\u0BCD 4 \u0B87\u0BB2\u0B95\u0BCD\u0B95 OTP \u0B95\u0BC7\u0BB3\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD',
                  verifyButtonLabel: 'Verify & Complete Delivery',
                  accentColor: DeliveryColors.stepDone,
                  isLoading: _isVerifying,
                  error: _error,
                  otpController: _otpController,
                  onCompleted: (pin) {
                    _verifyOtp();
                  },
                  onVerifyPressed: _verifyOtp,
                  onProblemPressed: _showProblemSheet,
                  topWidget: isCod && order != null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: DeliveryColors.stepPickup.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: DeliveryColors.stepPickup.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: DeliveryColors.stepPickup,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Remember to collect ${CurrencyUtil.format(order.finalAmount)} before entering OTP',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: DeliveryColors.stepPickup,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProblemOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProblemOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: DeliveryColors.textSecondary, size: 24),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DeliveryColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.notoSans(
          fontSize: 12,
          color: DeliveryColors.textSecondary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
