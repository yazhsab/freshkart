import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ─── String Extensions ───────────────────────────────────────────────────────

extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: "hello world" -> "Hello world"
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word.
  ///
  /// Example: "hello world" -> "Hello World"
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty (after trimming).
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Returns true if the string is not null and not empty (after trimming).
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

// ─── BuildContext Extensions ─────────────────────────────────────────────────

extension BuildContextExtensions on BuildContext {
  /// Shows a snackbar with the given message.
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an error snackbar with red background.
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a success snackbar with green background.
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Current theme data.
  ThemeData get theme => Theme.of(this);

  /// Current text theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Current color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Bottom padding (safe area).
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  /// Top padding (safe area / status bar).
  double get topPadding => MediaQuery.paddingOf(this).top;
}
