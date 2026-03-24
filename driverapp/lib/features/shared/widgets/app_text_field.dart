import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.textInputAction,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DeliveryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          textInputAction: textInputAction,
          autovalidateMode: autovalidateMode,
          textCapitalization: textCapitalization,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            color: DeliveryColors.textPrimary,
          ),
          cursorColor: DeliveryColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.notoSans(
              fontSize: 15,
              color: DeliveryColors.textSecondary.withOpacity(0.6),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: DeliveryColors.textSecondary,
                    size: 22,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled
                ? DeliveryColors.surface
                : DeliveryColors.background,
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _buildBorder(DeliveryColors.divider),
            enabledBorder: _buildBorder(DeliveryColors.divider),
            focusedBorder: _buildBorder(DeliveryColors.primary, width: 1.5),
            errorBorder: _buildBorder(DeliveryColors.newOrder),
            focusedErrorBorder: _buildBorder(
              DeliveryColors.newOrder,
              width: 1.5,
            ),
            disabledBorder: _buildBorder(
              DeliveryColors.divider.withOpacity(0.5),
            ),
            errorStyle: GoogleFonts.notoSans(
              fontSize: 12,
              color: DeliveryColors.newOrder,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
