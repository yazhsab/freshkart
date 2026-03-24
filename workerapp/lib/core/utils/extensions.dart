import 'package:flutter/material.dart';

extension StringX on String {
  bool get isValidPhone => RegExp(r'^[6-9]\d{9}$').hasMatch(this);
  bool get isValidAadhaar => RegExp(r'^\d{12}$').hasMatch(replaceAll(' ', ''));
  bool get isValidIfsc =>
      RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(toUpperCase());
  bool get isValidPincode => RegExp(r'^\d{6}$').hasMatch(this);

  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');
}

extension ContextX on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

extension DateTimeX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
