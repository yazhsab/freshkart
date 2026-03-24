import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';

class VendorTheme {
  VendorTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: VendorColors.primary,
      brightness: Brightness.light,
      primary: VendorColors.primary,
      secondary: VendorColors.pendingAmber,
      surface: VendorColors.surface,
      onSurface: VendorColors.textPrimary,
      error: VendorColors.error,
    ).copyWith(surfaceTint: Colors.transparent);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: VendorColors.background,
      canvasColor: VendorColors.background,
      fontFamily: GoogleFonts.manrope().fontFamily,
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: VendorColors.textPrimary,
        height: 1.08,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: VendorColors.textPrimary,
        height: 1.12,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: VendorColors.textPrimary,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: VendorColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: VendorColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: VendorColors.textPrimary,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: VendorColors.textSecondary,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: VendorColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VendorColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.manrope(
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
          foregroundColor: VendorColors.primary,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          side: BorderSide(
            color: VendorColors.primary.withValues(alpha: 0.16),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.62),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VendorColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: GoogleFonts.manrope(
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
        hintStyle: GoogleFonts.manrope(
          color: VendorColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.manrope(
          color: VendorColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: VendorColors.divider.withValues(alpha: 0.9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: VendorColors.divider.withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: VendorColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: VendorColors.cancelledOrder,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: VendorColors.cancelledOrder,
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
          side: BorderSide(color: VendorColors.divider.withValues(alpha: 0.8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VendorColors.primaryBg,
        selectedColor: VendorColors.primary,
        labelStyle: GoogleFonts.manrope(
          color: VendorColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VendorColors.textPrimary,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: VendorColors.divider.withValues(alpha: 0.85),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
