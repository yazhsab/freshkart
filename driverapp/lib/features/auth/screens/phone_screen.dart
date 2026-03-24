import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/auth/providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;
  bool _otpSending = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    final valid = phone.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
    if (valid != _isValid) {
      setState(() => _isValid = valid);
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phone = value.trim();
    if (phone.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Phone number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _otpSending = true);
    final phone = '+91${_phoneController.text.trim()}';
    await ref.read(authProvider.notifier).sendOtp(phone);

    if (mounted) {
      setState(() => _otpSending = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading || _otpSending;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthInitial && !_otpSending && previous is AuthLoading) {
        final phone = '+91${_phoneController.text.trim()}';
        context.push('/otp', extra: phone);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: DeliveryColors.newOrder,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F7),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -20,
            child: _GlowOrb(
              size: 220,
              color: DeliveryColors.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: _GlowOrb(
              size: 180,
              color: DeliveryColors.bonusGold.withValues(alpha: 0.14),
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
                  _buildLoginCard(isLoading),
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
            DeliveryColors.primaryDark,
            DeliveryColors.primary,
            DeliveryColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: DeliveryColors.primary.withValues(alpha: 0.24),
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
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 30,
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
                  'Dispatch Mode',
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
            'Start your day from a cleaner delivery cockpit.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Track available orders, active drops, earnings and route flow from one focused delivery experience.',
            style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'தினசரி வருமானத்திற்கான ஸ்மார்ட் டெலிவரி செயலி',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureBadge(icon: Icons.bolt_rounded, label: 'Fast dispatch'),
              _FeatureBadge(
                icon: Icons.route_rounded,
                label: 'Live route flow',
              ),
              _FeatureBadge(
                icon: Icons.payments_outlined,
                label: 'Daily earnings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: DeliveryColors.divider.withValues(alpha: 0.85),
        ),
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
            const Text(
              'Sign in with your mobile number',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the registered delivery partner number to receive a secure OTP.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: DeliveryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Phone number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: _validatePhone,
              enabled: !isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DeliveryColors.textPrimary,
                letterSpacing: 0.8,
              ),
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
                          color: DeliveryColors.primaryBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DeliveryColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 26,
                        color: DeliveryColors.divider,
                      ),
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
                disabledBackgroundColor: DeliveryColors.primary.withValues(
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBFB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: DeliveryColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'OTP login keeps dispatch access quick while protecting your partner account.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: DeliveryColors.textSecondary,
                      ),
                    ),
                  ),
                ],
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
