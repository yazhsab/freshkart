import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle get heading1 => GoogleFonts.notoSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading2 => GoogleFonts.notoSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading3 => GoogleFonts.notoSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading4 => GoogleFonts.notoSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Body
  static TextStyle get body1 => GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get body2 => GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Caption
  static TextStyle get caption => GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  // Button
  static TextStyle get button => GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Label
  static TextStyle get label => GoogleFonts.notoSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Price
  static TextStyle get price => GoogleFonts.notoSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryGreen,
    height: 1.2,
  );

  // Tamil subtitle — Noto Sans supports Tamil script
  static TextStyle get tamilSubtitle => GoogleFonts.notoSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
}
