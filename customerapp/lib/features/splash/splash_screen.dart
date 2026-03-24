import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for logo + brand name
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    // Fade animation for taglines
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController.forward().then((_) {
      _fadeController.forward();
    });

    // Navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;

    if (LocalStorage.isLoggedIn()) {
      context.go('/home');
    } else if (LocalStorage.getBool(LocalStorage.kOnboardingDone) == true) {
      context.go('/login');
    } else {
      context.go('/onboarding');
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo + brand
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, size: 80, color: AppColors.primaryGreen),
                  const SizedBox(height: 12),
                  Text(
                    'FreshKart',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Animated taglines
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fresh groceries & trusted services',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\u0BAA\u0BC1\u0BA4\u0BBF\u0BAF \u0BAA\u0BCA\u0BB0\u0BC1\u0B9F\u0BCD\u0B95\u0BB3\u0BCD \u0BAE\u0BB1\u0BCD\u0BB1\u0BC1\u0BAE\u0BCD \u0BA8\u0BAE\u0BCD\u0BAA\u0B95\u0BAE\u0BBE\u0BA9 \u0B9A\u0BC7\u0BB5\u0BC8\u0B95\u0BB3\u0BCD',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint),
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
