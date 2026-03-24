import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/category_model.dart';
import '../../../core/models/service_category_model.dart';
import '../../../core/theme/app_colors.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel> groceryCategories;
  final List<ServiceCategoryModel> serviceCategories;

  const CategoryGrid({
    super.key,
    required this.groceryCategories,
    required this.serviceCategories,
  });

  static const _groceryIcons = <String, String>{
    'vegetables': '\u{1F966}',
    'fruits': '\u{1F34E}',
    'dairy': '\u{1F95B}',
    'meat': '\u{1F356}',
    'snacks': '\u{1F36A}',
    'beverages': '\u{1F379}',
    'grains': '\u{1F33E}',
    'spices': '\u{1F336}',
    'oils': '\u{1FAD2}',
    'bakery': '\u{1F35E}',
    'frozen': '\u{2744}',
    'personal care': '\u{1F9F4}',
    'household': '\u{1F3E0}',
    'baby': '\u{1F476}',
  };

  static const _serviceIcons = <String, IconData>{
    'plumbing': Icons.plumbing,
    'electrical': Icons.electrical_services,
    'cleaning': Icons.cleaning_services,
    'painting': Icons.format_paint,
    'carpentry': Icons.carpenter,
    'pest control': Icons.bug_report,
    'appliance': Icons.settings,
    'ac service': Icons.ac_unit,
  };

  String _emojiForCategory(String name) {
    final lower = name.toLowerCase();
    for (final entry in _groceryIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '\u{1F6D2}';
  }

  IconData _iconForService(String name) {
    final lower = name.toLowerCase();
    for (final entry in _serviceIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.home_repair_service;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ...groceryCategories.map(
        (category) => _CategoryTileData(
          label: category.name,
          categoryType: 'Groceries',
          accentColor: AppColors.primaryGreen,
          backgroundColor: AppColors.backgroundGreen,
          leading: _EmojiBadge(emoji: _emojiForCategory(category.name)),
          onTap: () => context.push('/search?category=${category.id}'),
        ),
      ),
      ...serviceCategories.map(
        (service) => _CategoryTileData(
          label: service.name,
          categoryType: 'Services',
          accentColor: AppColors.primaryAmber,
          backgroundColor: AppColors.backgroundAmber,
          leading: Icon(
            _iconForService(service.name),
            color: AppColors.primaryAmber,
            size: 24,
          ),
          onTap: () => context.push('/services/${service.id}'),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1120
            ? 6
            : width >= 820
            ? 4
            : 3;
        const spacing = 12.0;
        final tileWidth = math.max<double>(
          104,
          (width - (spacing * (columns - 1))) / columns,
        );

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _CategoryTile(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CategoryTileData {
  final String label;
  final String categoryType;
  final Widget leading;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CategoryTileData({
    required this.label,
    required this.categoryType,
    required this.leading,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });
}

class _CategoryTile extends StatelessWidget {
  final _CategoryTileData item;

  const _CategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: item.accentColor.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.62),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: item.leading),
              ),
              const SizedBox(height: 16),
              Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.categoryType,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: item.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  final String emoji;

  const _EmojiBadge({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 24));
  }
}
