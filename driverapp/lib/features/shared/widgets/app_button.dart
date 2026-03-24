import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

enum AppButtonVariant { elevated, outlined, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;
  final IconData? icon;
  final double? height;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.elevated,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
    this.icon,
    this.height,
    this.fontSize,
    this.padding,
    this.color,
    this.borderRadius,
  });

  bool get _isEnabled => !isDisabled && !isLoading && onPressed != null;

  Color get _primaryColor => color ?? DeliveryColors.primary;

  @override
  Widget build(BuildContext context) {
    final buttonChild = _buildChild();
    final br = borderRadius ?? BorderRadius.circular(12);
    final h = height ?? 52.0;
    final fs = fontSize ?? 16.0;
    final textStyle = GoogleFonts.notoSans(
      fontSize: fs,
      fontWeight: FontWeight.w600,
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.elevated:
        button = ElevatedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _primaryColor.withOpacity(0.4),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
            minimumSize: Size(fullWidth ? double.infinity : 0, h),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: br),
            elevation: 0,
            textStyle: textStyle,
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            disabledForegroundColor: _primaryColor.withOpacity(0.4),
            minimumSize: Size(fullWidth ? double.infinity : 0, h),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: br),
            side: BorderSide(
              color: _isEnabled
                  ? _primaryColor
                  : _primaryColor.withOpacity(0.4),
              width: 1.5,
            ),
            textStyle: textStyle,
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: _isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
            disabledForegroundColor: _primaryColor.withOpacity(0.4),
            minimumSize: Size(fullWidth ? double.infinity : 0, h),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: br),
            textStyle: textStyle,
          ),
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.elevated ? Colors.white : _primaryColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      );
    }

    return Text(label);
  }
}
