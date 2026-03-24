import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class AdminNavItem extends StatefulWidget {
  const AdminNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    required this.onTap,
    this.collapsed = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  State<AdminNavItem> createState() => _AdminNavItemState();
}

class _AdminNavItemState extends State<AdminNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final collapsed = widget.collapsed;
    final foreground = isActive
        ? Colors.white
        : Colors.white.withValues(alpha: _hovering ? 0.92 : 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            horizontal: collapsed ? 10 : 14,
            vertical: 3,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.92),
                      AppColors.primaryDark.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive
                ? null
                : _hovering
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.26),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: collapsed
              ? Center(child: Icon(widget.icon, size: 21, color: foreground))
              : Row(
                  children: [
                    Icon(widget.icon, size: 20, color: foreground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
