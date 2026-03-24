import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';

class WorkerBottomNav extends StatelessWidget {
  final Widget child;

  const WorkerBottomNav({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/bookings')) return 1;
    if (location.startsWith('/schedule')) return 2;
    if (location.startsWith('/earnings')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: WorkerColors.background,
      body: child,
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.86),
                      WorkerColors.surface.withValues(alpha: 0.74),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: WorkerColors.primary.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: WorkerColors.primary.withValues(alpha: 0.1),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(
                      isActive: currentIndex == 0,
                      icon: Icons.home_rounded,
                      label: 'Home',
                      onTap: () => context.go('/home'),
                    ),
                    _NavItem(
                      isActive: currentIndex == 1,
                      icon: Icons.assignment_rounded,
                      label: 'Bookings',
                      onTap: () => context.go('/bookings'),
                    ),
                    _NavItem(
                      isActive: currentIndex == 2,
                      icon: Icons.calendar_month_rounded,
                      label: 'Schedule',
                      onTap: () => context.go('/schedule'),
                    ),
                    _NavItem(
                      isActive: currentIndex == 3,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Earnings',
                      onTap: () => context.go('/earnings'),
                    ),
                    _NavItem(
                      isActive: currentIndex == 4,
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      WorkerColors.primary.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color:
                isActive ? WorkerColors.primary.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? WorkerColors.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: WorkerColors.primary.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? WorkerColors.primary : Colors.transparent,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                size: 21,
                color: isActive
                    ? WorkerColors.primary
                    : WorkerColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                  color: isActive
                      ? WorkerColors.primary
                      : WorkerColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
