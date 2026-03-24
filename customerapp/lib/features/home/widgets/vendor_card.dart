import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/vendor_model.dart';
import '../../../core/theme/app_colors.dart';

class VendorCard extends StatelessWidget {
  final VendorModel vendor;

  const VendorCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/vendor/${vendor.id}'),
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            width: 256,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.borderStrong.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.62),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 126,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.darkGreen,
                        AppColors.primaryGreen,
                        AppColors.lightGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        top: -12,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _MetaBadge(
                                  icon: Icons.local_shipping_outlined,
                                  label:
                                      '${vendor.estimatedDeliveryMins ?? '--'} min',
                                ),
                                const Spacer(),
                                _MetaBadge(
                                  icon: vendor.isOpen
                                      ? Icons.bolt_rounded
                                      : Icons.pause_circle_outline_rounded,
                                  label: vendor.isOpen ? 'Open now' : 'Closed',
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.storefront_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              vendor.city,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.shopName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _DetailChip(
                              icon: Icons.star_rounded,
                              label:
                                  '${vendor.rating.toStringAsFixed(1)} (${vendor.totalRatings})',
                              color: AppColors.primaryAmber,
                            ),
                            const SizedBox(width: 8),
                            _DetailChip(
                              icon: Icons.place_outlined,
                              label:
                                  '${vendor.distance?.toStringAsFixed(1) ?? '--'} km',
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          vendor.description?.trim().isNotEmpty == true
                              ? vendor.description!
                              : '${vendor.address}, ${vendor.city}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_outward_rounded,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explore store',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
