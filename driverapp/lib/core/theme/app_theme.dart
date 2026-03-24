import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class DeliveryTheme {
  DeliveryTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DeliveryColors.primary,
      brightness: Brightness.light,
      primary: DeliveryColors.primary,
      secondary: DeliveryColors.bonusGold,
      surface: DeliveryColors.surface,
      onSurface: DeliveryColors.textPrimary,
      error: DeliveryColors.newOrder,
    ).copyWith(surfaceTint: Colors.transparent);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DeliveryColors.background,
      canvasColor: DeliveryColors.background,
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme)
        .copyWith(
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: DeliveryColors.textPrimary,
            height: 1.05,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: DeliveryColors.textPrimary,
            height: 1.1,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DeliveryColors.textPrimary,
          ),
          titleMedium: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: DeliveryColors.textPrimary,
          ),
          bodyLarge: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: DeliveryColors.textPrimary,
          ),
          bodyMedium: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: DeliveryColors.textPrimary,
          ),
          bodySmall: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DeliveryColors.textSecondary,
          ),
          labelLarge: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DeliveryColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: DeliveryColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DeliveryColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DeliveryColors.primary,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          side: BorderSide(
            color: DeliveryColors.primary.withValues(alpha: 0.16),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.62),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DeliveryColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
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
        labelStyle: GoogleFonts.spaceGrotesk(
          color: DeliveryColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.spaceGrotesk(
          color: DeliveryColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: DeliveryColors.divider.withValues(alpha: 0.9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: DeliveryColors.divider.withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: DeliveryColors.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: DeliveryColors.newOrder,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: DeliveryColors.newOrder,
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
          side: BorderSide(
            color: DeliveryColors.divider.withValues(alpha: 0.8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DeliveryColors.primaryBg,
        selectedColor: DeliveryColors.primary,
        labelStyle: GoogleFonts.spaceGrotesk(
          color: DeliveryColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: DeliveryColors.divider.withValues(alpha: 0.85),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DeliveryColors.textPrimary,
        contentTextStyle: GoogleFonts.spaceGrotesk(
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
