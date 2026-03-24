import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tamilSubtitle;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tamilSubtitle,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.local_shipping,
    iconColor: AppColors.primaryGreen,
    title: 'Fresh groceries delivered fast',
    subtitle:
        'Get farm-fresh vegetables, fruits, and essentials delivered to your doorstep in minutes.',
    tamilSubtitle:
        '\u0BAA\u0B9A\u0BCD\u0B9A\u0BC8 \u0B95\u0BBE\u0BAF\u0BCD\u0B95\u0BB1\u0BBF\u0B95\u0BB3\u0BCD, \u0BAA\u0BB4\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BAE\u0BB1\u0BCD\u0BB1\u0BC1\u0BAE\u0BCD \u0BA4\u0BC7\u0BB5\u0BC8\u0BAF\u0BBE\u0BA9\u0BB5\u0BC8 \u0BA8\u0BBF\u0BAE\u0BBF\u0B9F\u0B99\u0BCD\u0B95\u0BB3\u0BBF\u0BB2\u0BCD \u0BB5\u0BC7\u0B95\u0BAE\u0BBE\u0B95 \u0BAA\u0BC6\u0BB1\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.',
  ),
  _OnboardingPage(
    icon: Icons.home_repair_service,
    iconColor: AppColors.primaryAmber,
    title: 'Trusted home services',
    subtitle:
        'Book verified electricians, plumbers, cleaners and more for all your home needs.',
    tamilSubtitle:
        '\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BB5\u0BC0\u0B9F\u0BCD\u0B9F\u0BC1 \u0BA4\u0BC7\u0BB5\u0BC8\u0B95\u0BB3\u0BC1\u0B95\u0BCD\u0B95\u0BC1 \u0B9A\u0BB0\u0BBF\u0BAA\u0BBE\u0BB0\u0BCD\u0B95\u0BCD\u0B95\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F \u0BA4\u0BCA\u0BB4\u0BBF\u0BB2\u0BBE\u0BB3\u0BB0\u0BCD\u0B95\u0BB3\u0BC8 \u0BAA\u0BC1\u0B95\u0BCD \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.',
  ),
  _OnboardingPage(
    icon: Icons.payment,
    iconColor: AppColors.primaryGreen,
    title: 'Pay your way',
    subtitle:
        'UPI, cards, wallets, or cash on delivery \u2014 choose what works best for you.',
    tamilSubtitle:
        'UPI, \u0B95\u0BBE\u0BB0\u0BCD\u0B9F\u0BC1\u0B95\u0BB3\u0BCD, \u0BB5\u0BBE\u0BB2\u0BC6\u0B9F\u0BCD\u0B95\u0BB3\u0BCD \u0B85\u0BB2\u0BCD\u0BB2\u0BA4\u0BC1 \u0BAA\u0BA3\u0BAE\u0BCD \u0B9A\u0BC6\u0BB2\u0BC1\u0BA4\u0BCD\u0BA4\u0BC1\u0BAE\u0BCD\u0BAA\u0BCB\u0BA4\u0BC1 \u0BAA\u0BA3\u0BAE\u0BCD \u2014 \u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BC1\u0B95\u0BCD\u0B95\u0BC1 \u0B8F\u0BB1\u0BCD\u0BB1\u0BA4\u0BC8 \u0BA4\u0BC7\u0BB0\u0BCD\u0BB5\u0BC1 \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onComplete() async {
    await LocalStorage.setBool(LocalStorage.kOnboardingDone, true);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 120, color: page.iconColor),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.tamilSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots indicator
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: AppColors.primaryGreen,
                dotColor: AppColors.divider,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isLastPage
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Get Started'),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _onComplete,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
