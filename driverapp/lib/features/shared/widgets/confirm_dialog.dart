import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
  });

  /// Shows a confirmation dialog and returns `true` if confirmed,
  /// `false` if cancelled or dismissed.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDestructive
        ? DeliveryColors.newOrder
        : DeliveryColors.primary;

    return AlertDialog(
      backgroundColor: DeliveryColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DeliveryColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          color: DeliveryColors.textSecondary,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: DeliveryColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(cancelText),
        ),
        const SizedBox(width: 4),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            textStyle: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
