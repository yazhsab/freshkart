import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatError(e);
          _loading = false;
        });
      }
    }
  }

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('Admin privileges required')) {
      return 'Access denied. Admin privileges required.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email address first.';
    }
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;

                      final form = _LoginFormCard(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscure: _obscure,
                        loading: _loading,
                        error: _error,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _submit,
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            const _LoginHeroPanel(compact: true),
                            const SizedBox(height: 18),
                            form,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Expanded(flex: 6, child: _LoginHeroPanel()),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: form),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.spotlight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.spotlightAmber.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeroPanel extends StatelessWidget {
  final bool compact;

  const _LoginHeroPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sidebar, AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroBadge(label: 'Admin workspace'),
              _HeroBadge(label: 'Live operations'),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 26),
          Text(
            'FreshKart admin, redesigned for a sharper operations flow.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: compact ? 32 : 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A cleaner hierarchy for monitoring grocery, services, payouts and platform growth from one command surface.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          if (!compact)
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SignalCard(
                  title: 'Real-time visibility',
                  subtitle:
                      'Monitor orders, bookings and alerts with less clutter.',
                  icon: Icons.visibility_outlined,
                ),
                _SignalCard(
                  title: 'Operational focus',
                  subtitle:
                      'Move faster with stronger contrast and denser signal design.',
                  icon: Icons.auto_graph_rounded,
                ),
              ],
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Role-based admin access only. Use your verified FreshKart account to continue.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool loading;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginFormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.44),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in to continue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Use your admin credentials to access the redesigned control center.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (error != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'admin@freshkart.in',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Password is required';
                }
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SignalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
