import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/auth/providers/auth_provider.dart';
import 'package:freshkart_customer/features/auth/providers/auth_state.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _countdown = 30;
  bool _canResend = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        if (mounted) {
          setState(() => _canResend = true);
        }
      } else {
        if (mounted) {
          setState(() => _countdown--);
        }
      }
    });
  }

  Future<void> _onVerify(String otp) async {
    if (otp.length != 6) return;
    setState(() => _errorText = null);
    await ref.read(authProvider.notifier).verifyOtp(widget.phone, otp);
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    _otpController.clear();
    setState(() => _errorText = null);
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _maskedPhone {
    final phone = widget.phone;
    if (phone.length >= 10) {
      return '+91 ${'X' * 6}${phone.substring(6)}';
    }
    return '+91 $phone';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go('/home');
      } else if (next is AuthError) {
        setState(() => _errorText = next.message);
      }
    });

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryGreen, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.error),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'OTP sent to $_maskedPhone',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'OTP \u0B85\u0BA9\u0BC1\u0BAA\u0BCD\u0BAA\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F\u0BA4\u0BC1',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
              const SizedBox(height: 36),

              // OTP input
              Center(
                child: Pinput(
                  controller: _otpController,
                  focusNode: _focusNode,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  errorPinTheme: errorPinTheme,
                  enabled: !isLoading,
                  onCompleted: _onVerify,
                  keyboardType: TextInputType.number,
                ),
              ),

              // Error text
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Countdown / Resend
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _onResend,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : Text(
                        'Resend OTP in ${_countdown}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _onVerify(_otpController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.4,
                    ),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
