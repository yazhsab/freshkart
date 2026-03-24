import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class CheckinOtpWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCompleted;

  const CheckinOtpWidget({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 60,
      height: 68,
      textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Pinput(
      length: 4,
      controller: controller,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: BoxDecoration(
          border: Border.all(color: WorkerColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onCompleted: onCompleted,
    );
  }
}
