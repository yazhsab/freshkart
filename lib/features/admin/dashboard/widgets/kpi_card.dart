import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

/// A specialized KPI card for the admin dashboard.
/// Extends the base StatCard concept with badge support and colored accent bar.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    this.iconBackgroundColor,
    this.badgeCount = 0,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final Color? iconBackgroundColor;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconBg = iconBackgroundColor ?? accentColor.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconBg, accentColor.withValues(alpha: 0.12)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeCount > 0) _buildBadge(),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.spotlightAmber,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badgeCount.toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
