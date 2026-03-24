import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class OtpVerifyCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tamilInstruction;
  final String verifyButtonLabel;
  final Color accentColor;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onCompleted;
  final VoidCallback onVerifyPressed;
  final VoidCallback? onProblemPressed;
  final TextEditingController otpController;
  final Widget? topWidget;

  const OtpVerifyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tamilInstruction,
    required this.verifyButtonLabel,
    this.accentColor = DeliveryColors.primary,
    this.isLoading = false,
    this.error,
    required this.onCompleted,
    required this.onVerifyPressed,
    this.onProblemPressed,
    required this.otpController,
    this.topWidget,
  });

  @override
  State<OtpVerifyCard> createState() => _OtpVerifyCardState();
}

class _OtpVerifyCardState extends State<OtpVerifyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(OtpVerifyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && oldWidget.error != widget.error) {
      _triggerShake();
    }
  }

  void _triggerShake() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: GoogleFonts.notoSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: DeliveryColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: DeliveryColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DeliveryColors.divider, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accentColor, width: 2),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red, width: 2),
      ),
    );

    return Column(
      children: [
        if (widget.topWidget != null) ...[
          widget.topWidget!,
          const SizedBox(height: 20),
        ],

        // Instruction card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accentColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.accentColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tamilInstruction,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: widget.accentColor.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // OTP Pinput with shake animation
        AnimatedBuilder2(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shakeVal = _shakeAnimation.value;
            final dx = shakeVal * 10 * ((shakeVal * 8).toInt().isEven ? 1 : -1);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Pinput(
            controller: widget.otpController,
            focusNode: _focusNode,
            length: 4,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            errorPinTheme: errorPinTheme,
            keyboardType: TextInputType.number,
            autofocus: true,
            onCompleted: widget.onCompleted,
            hapticFeedbackType: HapticFeedbackType.mediumImpact,
          ),
        ),

        // Error message
        if (widget.error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onVerifyPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: widget.accentColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.verifyButtonLabel,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        // Problem link
        if (widget.onProblemPressed != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onProblemPressed,
            child: Text(
              'Problem with OTP?',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: DeliveryColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
