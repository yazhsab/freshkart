import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_delivery/core/theme/app_colors.dart';

class AgentBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int currentIndex;

  const AgentBottomNav({
    super.key,
    required this.navigationShell,
    required this.currentIndex,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeliveryColors.background,
      body: navigationShell,
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
                      DeliveryColors.surface.withValues(alpha: 0.74),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: DeliveryColors.primary.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DeliveryColors.primary.withValues(alpha: 0.1),
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
                      onTap: () => _onTap(0),
                    ),
                    _NavItem(
                      isActive: currentIndex == 1,
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => _onTap(1),
                    ),
                    _NavItem(
                      isActive: currentIndex == 2,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Earnings',
                      onTap: () => _onTap(2),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      DeliveryColors.primary.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isActive
                ? DeliveryColors.primary.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? DeliveryColors.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: DeliveryColors.primary.withValues(alpha: 0.16),
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
                  color: isActive ? DeliveryColors.primary : Colors.transparent,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? DeliveryColors.primary
                    : DeliveryColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? DeliveryColors.primary
                      : DeliveryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
