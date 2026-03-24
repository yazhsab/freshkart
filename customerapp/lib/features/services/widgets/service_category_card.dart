import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/models/service_category_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

class ServiceCategoryCard extends StatelessWidget {
  final ServiceCategoryModel category;

  const ServiceCategoryCard({super.key, required this.category});

  IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing;
    if (lower.contains('electric')) return Icons.electrical_services;
    if (lower.contains('clean')) return Icons.cleaning_services;
    if (lower.contains('paint')) return Icons.format_paint;
    if (lower.contains('carpenter') || lower.contains('wood')) {
      return Icons.carpenter;
    }
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('pest')) return Icons.bug_report;
    if (lower.contains('garden') || lower.contains('lawn')) return Icons.yard;
    if (lower.contains('appliance')) return Icons.kitchen;
    if (lower.contains('salon') || lower.contains('beauty')) {
      return Icons.content_cut;
    }
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/services/${category.id}'),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryAmber.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAmber.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.backgroundAmber,
                      AppColors.spotlightPeach,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Icon(
                  _iconForCategory(category.name),
                  size: 28,
                  color: AppColors.primaryAmber,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (category.description?.trim().isNotEmpty == true)
                Text(
                  category.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ServiceMetaChip(
                    icon: Icons.schedule_rounded,
                    label: '${category.estimatedDurationMins} min',
                  ),
                  _ServiceMetaChip(
                    icon: Icons.currency_rupee_rounded,
                    label: 'From ${category.basePrice.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundAmber,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryAmber),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryAmber,
            ),
          ),
        ],
      ),
    );
  }
}
