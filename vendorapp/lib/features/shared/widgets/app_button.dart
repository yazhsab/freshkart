import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.width,
  });

  bool get _isDisabled => onPressed == null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? VendorColors.primary;

    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor, width: 1.5),
            minimumSize: Size(width ?? double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledForegroundColor: buttonColor.withValues(alpha: 0.4),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            minimumSize: Size(width ?? double.infinity, 52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: buttonColor.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: child,
            ),
    );
  }
}
