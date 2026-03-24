import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController.forward();

    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeController.forward();
      }
    });

    // Check auth and navigate after splash delay
    Future.delayed(const Duration(seconds: 2), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    await ref.read(authProvider.notifier).checkAuth();

    if (!mounted) return;

    final state = ref.read(authProvider);

    if (state is AuthAuthenticated) {
      context.go('/home');
    } else if (state is AuthPendingApproval) {
      context.go('/pending-approval');
    } else if (state is AuthNeedsRegistration) {
      context.go('/register-agent');
    } else {
      // AuthUnauthenticated, AuthError, or anything else
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DeliveryColors.primaryDark,
              DeliveryColors.primary,
              DeliveryColors.primaryLight,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with scale animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delivery truck icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FreshKart text
                    const Text(
                      'FreshKart',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Delivery subtitle badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DELIVERY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Tagline with fade
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'Deliver fresh, earn daily',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      '\u0BAA\u0B9A\u0BCD\u0B9A\u0BC8\u0BAF\u0BBE\u0B95 \u0BB5\u0BBF\u0BA9\u0BBF\u0BAF\u0BCB\u0B95\u0BAE\u0BCD, \u0BA4\u0BBF\u0BA9\u0BAE\u0BCD \u0BB5\u0BB0\u0BC1\u0BAE\u0BBE\u0BA9\u0BAE\u0BCD',
                      style: TextStyle(fontSize: 13, color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Loading spinner
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
