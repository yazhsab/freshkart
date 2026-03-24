import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';

class VendorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingOrderCount;
  final int lowStockCount;

  const VendorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.pendingOrderCount = 0,
    this.lowStockCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    VendorColors.surface.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: VendorColors.primary.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: VendorColors.primary.withValues(alpha: 0.1),
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
                  _buildNavItem(
                    index: 0,
                    icon: Icons.space_dashboard_rounded,
                    label: 'Dashboard',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.receipt_long_rounded,
                    label: 'Orders',
                    badgeCount: pendingOrderCount,
                    accentColor: VendorColors.newOrder,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.inventory_2_rounded,
                    label: 'Inventory',
                    badgeCount: lowStockCount,
                    accentColor: VendorColors.pendingAmber,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.storefront_rounded,
                    label: 'Shop',
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
    Color accentColor = VendorColors.primary,
  }) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
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
                      accentColor.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isActive ? accentColor.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.16),
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
                  color: isActive ? accentColor : Colors.transparent,
                ),
              ),
              const SizedBox(height: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isActive ? accentColor : VendorColors.textSecondary,
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
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(999),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.26),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                  color: isActive ? accentColor : VendorColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
