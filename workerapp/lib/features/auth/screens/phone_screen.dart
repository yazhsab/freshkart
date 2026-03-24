import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/auth/providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      final phone = _phoneController.text.trim();
      final valid = RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
      if (valid != _isValid) {
        setState(() => _isValid = valid);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).sendOtp(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.status == AuthStatus.otpSent) {
        context.pushNamed('otp', extra: _phoneController.text.trim());
      } else if (next.status == AuthStatus.error && next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F1),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: _GlowOrb(
              size: 220,
              color: WorkerColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: 150,
            left: -70,
            child: _GlowOrb(
              size: 180,
              color: WorkerColors.bonusGold.withValues(alpha: 0.16),
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
                  _buildLoginCard(authState.status == AuthStatus.loading),
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
            WorkerColors.primaryDark,
            WorkerColors.primary,
            WorkerColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: WorkerColors.primary.withValues(alpha: 0.26),
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
                  Icons.engineering_rounded,
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
                  'Pro Service App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Turn your skills into a polished daily workflow.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage bookings, availability, earnings and job progress from a single pro dashboard.',
            style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'சேவை வல்லுநர்களுக்கான நவீன செயலி',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureBadge(
                icon: Icons.event_available_rounded,
                label: 'Booking control',
              ),
              _FeatureBadge(
                icon: Icons.verified_user_outlined,
                label: 'Verified profile',
              ),
              _FeatureBadge(
                icon: Icons.payments_outlined,
                label: 'Fast payouts',
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
        border: Border.all(color: WorkerColors.divider.withValues(alpha: 0.85)),
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
                fontWeight: FontWeight.w800,
                color: WorkerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the number linked to your worker account to receive a secure OTP.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: WorkerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Phone number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: WorkerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Enter mobile number';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: '9876543210',
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
                          color: WorkerColors.primaryBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: WorkerColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 26,
                        color: WorkerColors.divider,
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isValid && !isLoading ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: WorkerColors.primary.withValues(
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
                  : const Text('Continue'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: WorkerColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This sign-in keeps your bookings, documents and bank details protected.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: WorkerColors.textSecondary,
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
              fontWeight: FontWeight.w800,
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
