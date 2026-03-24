import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int activeOrderCount;
  final int activeBookingCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeOrderCount = 0,
    this.activeBookingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    AppColors.surfaceAlt.withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.receipt_long_rounded,
                    label: 'Orders',
                    badgeCount: activeOrderCount,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.home_repair_service_rounded,
                    label: 'Services',
                    badgeCount: activeBookingCount,
                    useAmberAccent: true,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
    bool useAmberAccent = false,
  }) {
    final isActive = currentIndex == index;
    final accentColor = useAmberAccent
        ? AppColors.primaryAmber
        : AppColors.primaryGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.18),
                      accentColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isActive ? accentColor : AppColors.textHint,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
