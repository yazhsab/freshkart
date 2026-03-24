import 'package:flutter/material.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

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
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primaryGreen;
    final isDisabled = onPressed == null && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: isOutlined
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: buttonColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: buttonColor,
                ),
                child: _buildChild(buttonColor),
              )
            : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: buttonColor,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _buildChild(Colors.white),
              ),
      ),
    );
  }

  Widget _buildChild(Color contentColor) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
