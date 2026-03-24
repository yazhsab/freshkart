import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/models/category_model.dart';

class CategoryFilter extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildChip(
              label: 'All',
              isSelected: selectedId == null,
              onTap: () => onSelected(null),
            );
          }

          final category = categories[index - 1];
          return _buildChip(
            label: category.name,
            isSelected: selectedId == category.id,
            onTap: () => onSelected(category.id),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VendorColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VendorColors.primary : VendorColors.divider,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : VendorColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
