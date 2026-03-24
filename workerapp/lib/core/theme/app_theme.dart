import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: WorkerColors.primary,
      brightness: Brightness.light,
      primary: WorkerColors.primary,
      secondary: WorkerColors.bonusGold,
      surface: WorkerColors.surface,
      onSurface: WorkerColors.textPrimary,
      error: WorkerColors.jobCancelled,
    ).copyWith(surfaceTint: Colors.transparent);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WorkerColors.background,
      canvasColor: WorkerColors.background,
      fontFamily: GoogleFonts.sora().fontFamily,
    );

    final textTheme = GoogleFonts.soraTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.sora(
        fontSize: 31,
        fontWeight: FontWeight.w800,
        color: WorkerColors.textPrimary,
        height: 1.08,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: WorkerColors.textPrimary,
        height: 1.12,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: WorkerColors.textPrimary,
      ),
      titleMedium: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: WorkerColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: WorkerColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.sora(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: WorkerColors.textPrimary,
      ),
      bodySmall: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: WorkerColors.textSecondary,
      ),
      labelLarge: GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: WorkerColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WorkerColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WorkerColors.primary,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          side: BorderSide(
            color: WorkerColors.primary.withValues(alpha: 0.16),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.62),
          textStyle: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WorkerColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.sora(
          color: WorkerColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.sora(
          color: WorkerColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: WorkerColors.divider.withValues(alpha: 0.9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: WorkerColors.divider.withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: WorkerColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: WorkerColors.jobCancelled,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: WorkerColors.jobCancelled,
            width: 1.6,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: WorkerColors.divider.withValues(alpha: 0.8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: WorkerColors.primaryBg,
        selectedColor: WorkerColors.primary,
        labelStyle: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: WorkerColors.primary,
        ),
        secondaryLabelStyle: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: WorkerColors.divider.withValues(alpha: 0.85),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WorkerColors.textPrimary,
        contentTextStyle: GoogleFonts.sora(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
