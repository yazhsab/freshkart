import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
              ),
              showCheckmark: false,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        }).toList(),
      ),
    );
  }
}
