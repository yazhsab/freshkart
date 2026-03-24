import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/auth/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _onVerify() async {
    if (_pinController.text.length != 6) return;
    setState(() => _errorText = null);
    await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.phone, _pinController.text);
  }

  Future<void> _onOtpCompleted(String otp) async {
    if (otp.length != 6) return;
    setState(() => _errorText = null);
    await ref.read(authProvider.notifier).verifyOtp(widget.phone, otp);
  }

  Future<void> _onResendOtp() async {
    if (!_canResend) return;
    _pinController.clear();
    setState(() => _errorText = null);
    _startTimer();
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
  }

  String get _maskedPhone {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return widget.phone;
    final visiblePrefix = digits.substring(0, 2);
    final visibleSuffix = digits.substring(digits.length - 3);
    final masked = '$visiblePrefix${'*' * (digits.length - 5)}$visibleSuffix';
    if (widget.phone.startsWith('+')) {
      return '+${masked.substring(0, 2)} ${masked.substring(2)}';
    }
    return masked;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        setState(() => _errorText = next.message);
        _pinController.clear();
        _focusNode.requestFocus();
      }
    });

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: VendorColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VendorColors.divider),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: VendorColors.primaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VendorColors.primary, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: VendorColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: VendorColors.primaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VendorColors.primaryLight),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VendorColors.cancelledOrder),
      ),
    );

    return Scaffold(
      backgroundColor: VendorColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: VendorColors.primary.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 160,
            left: -60,
            child: _GlowOrb(
              size: 180,
              color: VendorColors.pendingAmber.withValues(alpha: 0.14),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: VendorColors.divider.withValues(alpha: 0.9),
                          ),
                        ),
                        child: IconButton(
                          onPressed: isLoading ? null : () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: VendorColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: VendorColors.primaryBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Step 2 of 2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: VendorColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _HeroCard(maskedPhone: _maskedPhone),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.96),
                          VendorColors.surface.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: VendorColors.divider.withValues(alpha: 0.88),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter the 6-digit code',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: VendorColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'We sent a secure login code to $_maskedPhone.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: VendorColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: isLoading ? null : () => context.pop(),
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Pinput(
                            length: 6,
                            controller: _pinController,
                            focusNode: _focusNode,
                            defaultPinTheme: _errorText != null
                                ? errorPinTheme
                                : defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: _errorText != null
                                ? errorPinTheme
                                : submittedPinTheme,
                            enabled: !isLoading,
                            onCompleted: _onOtpCompleted,
                            closeKeyboardWhenCompleted: true,
                            keyboardType: TextInputType.number,
                            pinAnimationType: PinAnimationType.fade,
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorText!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: VendorColors.cancelledOrder,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: isLoading ? null : _onVerify,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Verify and continue'),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _canResend
                              ? TextButton(
                                  onPressed: _onResendOtp,
                                  child: const Text('Resend OTP'),
                                )
                              : Text(
                                  'Resend available in $_secondsRemaining s',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: VendorColors.textSecondary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: VendorColors.primaryBg.withValues(
                              alpha: 0.72,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: VendorColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'OTP verification protects your store controls, payouts, and order actions.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                    color: VendorColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String maskedPhone;

  const _HeroCard({required this.maskedPhone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            VendorColors.primaryDark,
            VendorColors.primary,
            VendorColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: VendorColors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  maskedPhone,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Secure your vendor workspace.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.08,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'One quick verification unlocks your order command center, inventory controls, and earnings view.',
            style: TextStyle(fontSize: 14, height: 1.45, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
