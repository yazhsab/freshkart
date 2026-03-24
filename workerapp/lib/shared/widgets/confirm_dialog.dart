import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : WorkerColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
