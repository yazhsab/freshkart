import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'today',
          label: Text('Today'),
          icon: Icon(Icons.today, size: 18),
        ),
        ButtonSegment<String>(
          value: 'week',
          label: Text('This Week'),
          icon: Icon(Icons.date_range, size: 18),
        ),
        ButtonSegment<String>(
          value: 'month',
          label: Text('This Month'),
          icon: Icon(Icons.calendar_month, size: 18),
        ),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (Set<String> newSelection) {
        onChanged(newSelection.first);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return VendorColors.primary;
          }
          return VendorColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return VendorColors.textSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: VendorColors.divider),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
