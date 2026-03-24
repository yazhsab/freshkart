import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';
import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/models/profile_model.dart';
import 'package:freshkart_vendor/core/models/vendor_model.dart';

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

    Future.delayed(const Duration(seconds: 2), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final storage = LocalStorage.instance;

    if (!storage.isLoggedIn) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      // Verify token by fetching profile
      final profileResponse = await ApiClient.instance.get('/auth/profile');
      final profileData = profileResponse.data as Map<String, dynamic>;
      final profile = ProfileModel.fromJson(profileData);

      // Check role is vendor
      if (profile.role != 'vendor') {
        await storage.clearSession();
        if (mounted) context.go('/login');
        return;
      }

      // Fetch vendor profile
      try {
        final vendorResponse = await ApiClient.instance.get('/vendors/me');
        final vendorData = vendorResponse.data as Map<String, dynamic>;
        final vendor = VendorModel.fromJson(vendorData);

        if (mounted) {
          if (vendor.isApproved) {
            context.go('/dashboard');
          } else {
            context.go('/pending-approval');
          }
        }
      } catch (vendorError) {
        // No vendor record found - needs to register
        if (mounted) context.go('/register-vendor');
      }
    } catch (e) {
      // Token invalid or network error
      await storage.clearSession();
      if (mounted) context.go('/login');
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Green eco icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: VendorColors.primaryBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 48,
                      color: VendorColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // FreshKart text
                  const Text(
                    'FreshKart',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: VendorColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Partner subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Partner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF9A825),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Tagline with fade
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    'Manage your shop, grow your business',
                    style: TextStyle(
                      fontSize: 15,
                      color: VendorColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B95\u0B9F\u0BC8\u0BAF\u0BC8 \u0BA8\u0BBF\u0BB0\u0BCD\u0BB5\u0B95\u0BBF\u0B95\u0BCD\u0B95\u0BB5\u0BC1\u0BAE\u0BCD',
                    style: TextStyle(
                      fontSize: 13,
                      color: VendorColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
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
