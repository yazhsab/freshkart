import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.onTap,
    this.readOnly = false,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VendorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          onTap: onTap,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 15, color: VendorColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: VendorColors.textHint,
              fontSize: 15,
            ),
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: VendorColors.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: VendorColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: VendorColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: VendorColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
