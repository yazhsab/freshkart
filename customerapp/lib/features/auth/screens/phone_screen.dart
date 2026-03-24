import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/auth/providers/auth_provider.dart';
import 'package:freshkart_customer/features/auth/providers/auth_state.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;
  bool _showReferralInput = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  bool _validatePhone(String value) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(value);
  }

  void _onPhoneChanged(String value) {
    setState(() {
      _isValid = _validatePhone(value);
    });
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    await ref.read(authProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthOtpSent) {
        context.push('/otp?phone=${next.phone}');
      } else if (next is AuthAuthenticated) {
        context.go('/home');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F2),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -30,
            child: _GlowOrb(
              size: 220,
              color: AppColors.primaryGreen.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: _GlowOrb(
              size: 180,
              color: AppColors.primaryAmber.withValues(alpha: 0.14),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  _buildFormCard(context, isLoading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.darkGreen,
            AppColors.primaryGreen,
            AppColors.lightGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
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
                child: const Text(
                  'Local • Fast • Trusted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'FreshKart',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Premium grocery delivery and home services built for everyday convenience.',
            style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'புதிய பொருட்கள் மற்றும் நம்பகமான சேவைகள்',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureBadge(
                icon: Icons.timer_outlined,
                label: 'Quick delivery',
              ),
              _FeatureBadge(
                icon: Icons.storefront_rounded,
                label: 'Local stores',
              ),
              _FeatureBadge(
                icon: Icons.verified_user_outlined,
                label: 'Trusted professionals',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue with your mobile number',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in once and manage orders, payments, addresses and bookings from one place.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Phone number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              onChanged: _onPhoneChanged,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!_validatePhone(value)) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 8, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 26, color: AppColors.divider),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: '9876543210',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isValid && !isLoading ? _onSendOtp : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppColors.primaryGreen.withValues(
                  alpha: 0.35,
                ),
                disabledForegroundColor: Colors.white70,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send OTP'),
            ),
            const SizedBox(height: 20),

            // ── OR divider ──
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.divider,
                    thickness: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.divider,
                    thickness: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Google Sign-In ──
            OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () => ref.read(authProvider.notifier).signInWithGoogle(
                        referralCode: _referralController.text.trim(),
                      ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Apple Sign-In (iOS only) ──
            if (!kIsWeb && Platform.isIOS) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => ref.read(authProvider.notifier).signInWithApple(
                          referralCode: _referralController.text.trim(),
                        ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Continue with Apple',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Referral Code ──
            GestureDetector(
              onTap: () {
                setState(() {
                  _showReferralInput = !_showReferralInput;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showReferralInput
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Have a referral code?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            if (_showReferralInput) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _referralController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter referral code',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.card_giftcard_rounded,
                    size: 20,
                    color: AppColors.primaryGreen,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBF7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We only use OTP for secure sign-in. No passwords to remember.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'By continuing, you agree to FreshKart terms and privacy policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
