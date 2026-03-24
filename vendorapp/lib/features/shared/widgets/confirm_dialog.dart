import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VendorColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            color: VendorColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                color: VendorColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive
                    ? VendorColors.error
                    : VendorColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
