import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryGreen,
          onPrimary: Colors.white,
          secondary: AppColors.primaryAmber,
          onSecondary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: GoogleFonts.manrope().fontFamily,
    );

    final bodyTheme = GoogleFonts.manropeTextTheme(base.textTheme);
    final textTheme = bodyTheme.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -1.3,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.05,
        letterSpacing: -1.1,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -0.9,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          side: BorderSide(
            color: AppColors.primaryGreen.withValues(alpha: 0.16),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface.withValues(alpha: 0.94),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.borderStrong.withValues(alpha: 0.92),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.borderStrong.withValues(alpha: 0.92),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.7,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface.withValues(alpha: 0.94),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppColors.borderStrong.withValues(alpha: 0.72),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundGreen,
        selectedColor: AppColors.primaryGreen,
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryGreen,
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider.withValues(alpha: 0.85),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            color: isSelected ? AppColors.primaryGreen : AppColors.textHint,
          );
        }),
      ),
    );
  }
}
