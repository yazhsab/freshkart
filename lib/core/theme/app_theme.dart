import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          error: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.manrope().fontFamily,
    );

    final bodyTheme = GoogleFonts.manropeTextTheme(base.textTheme);
    final textTheme = bodyTheme.copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -1.1,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.05,
        letterSpacing: -0.9,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 15,
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
    );

    return base.copyWith(
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.18),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.92),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.92),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.manrope(fontSize: 14, color: AppColors.textHint),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.spotlight,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
