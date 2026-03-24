import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';
import 'package:freshkart_delivery/features/delivery/providers/active_delivery_provider.dart';
import 'package:freshkart_delivery/features/delivery/widgets/otp_verify_card.dart';

class PickupOtpScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PickupOtpScreen({super.key, required this.orderId});

  @override
  ConsumerState<PickupOtpScreen> createState() => _PickupOtpScreenState();
}

class _PickupOtpScreenState extends ConsumerState<PickupOtpScreen> {
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
        .confirmPickup(widget.orderId, otp);

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (success) {
      // Brief success indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pickup confirmed!',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: DeliveryColors.stepDone,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Update phase and navigate to dropoff
      ref
          .read(deliveryProvider.notifier)
          .setPhase(DeliveryPhase.goingToCustomer);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/delivery/${widget.orderId}');
      }
    } else {
      final activeError = ref.read(activeDeliveryProvider).error;
      setState(() {
        _error = activeError ?? 'Wrong OTP. Ask vendor to check.';
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
                'What\'s the problem?',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _ProblemOption(
                icon: Icons.smartphone_outlined,
                title: "Vendor doesn't have OTP",
                subtitle: 'Ask vendor to check their app notifications',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ask the vendor to open their FreshKart app and check the OTP',
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
                icon: Icons.phone_android_outlined,
                title: 'App not working',
                subtitle: 'Report a technical issue',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Issue reported. Our support team will contact you shortly.',
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
                icon: Icons.cancel_outlined,
                title: 'Cancel delivery',
                subtitle: 'This may affect your ratings',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _showCancelConfirmation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Delivery?',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this delivery? This may affect your performance rating.',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: DeliveryColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'No, continue',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                color: DeliveryColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: Text(
              'Yes, cancel',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final order = deliveryState.order;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DeliveryColors.surface,
        appBar: AppBar(
          backgroundColor: DeliveryColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Verify Pickup',
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
                  'Verify pickup at vendor',
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: DeliveryColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                if (order != null) ...[
                  Text(
                    order.vendorName,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.vendorAddress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // OTP Card
                OtpVerifyCard(
                  title: 'Verify Pickup',
                  subtitle: 'Ask vendor for the 4-digit OTP shown on their app',
                  tamilInstruction:
                      '\u0BAA\u0BC7\u0B95\u0BCD\u0B95\u0BC7\u0B9C\u0BCD \u0BAA\u0BC6\u0BB1 \u0B95\u0B9F\u0BC8\u0B95\u0BCD\u0B95\u0BBE\u0BB0\u0BB0\u0BCD \u0B95\u0BCA\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BC1\u0BAE\u0BCD 4 \u0B87\u0BB2\u0B95\u0BCD\u0B95 OTP \u0B90 \u0B89\u0BB3\u0BCD\u0BB3\u0BBF\u0B9F\u0BB5\u0BC1\u0BAE\u0BCD',
                  verifyButtonLabel: 'Verify & Confirm Pickup',
                  accentColor: DeliveryColors.primary,
                  isLoading: _isVerifying,
                  error: _error,
                  otpController: _otpController,
                  onCompleted: (pin) {
                    _verifyOtp();
                  },
                  onVerifyPressed: _verifyOtp,
                  onProblemPressed: _showProblemSheet,
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
  final bool isDestructive;

  const _ProblemOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : DeliveryColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : DeliveryColors.textPrimary,
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
