import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final void Function(String)? onChanged;
  final int? maxLength;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
