import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({
    super.key,
    required this.onPressed,
    this.label = 'Export CSV',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.download_outlined, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
