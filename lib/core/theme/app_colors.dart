import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand
  static const primary = Color(0xFF0F7A5C);
  static const primaryDark = Color(0xFF082F24);
  static const secondary = Color(0xFFF0A33A);
  static const primaryGreen = primary;
  static const lightGreen = Color(0xFF3CCB98);
  static const darkGreen = primaryDark;
  static const backgroundGreen = Color(0xFFE3F7EE);

  // Services (amber)
  static const primaryAmber = secondary;
  static const lightAmber = Color(0xFFFFC86E);
  static const backgroundAmber = Color(0xFFFFF1D8);

  // Neutral
  static const background = Color(0xFFF5F6F1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F5EF);
  static const divider = Color(0xFFD9E2DA);
  static const border = divider;
  static const textPrimary = Color(0xFF15231C);
  static const textSecondary = Color(0xFF677468);
  static const textHint = Color(0xFF97A49A);
  static const spotlight = backgroundGreen;
  static const spotlightAmber = Color(0xFFFFE8C9);
  static const shadow = Color(0x140B2118);

  // Status
  static const success = Color(0xFF26A269);
  static const warning = Color(0xFFF29B38);
  static const error = Color(0xFFD8514E);
  static const info = Color(0xFF2E84D8);

  // Order status
  static const statusPending = Color(0xFF9E9E9E);
  static const statusConfirmed = Color(0xFF2E84D8);
  static const statusPacking = Color(0xFF6E76D9);
  static const statusReady = Color(0xFFF29B38);
  static const statusPickedUp = Color(0xFFEC7A31);
  static const statusDelivered = Color(0xFF26A269);
  static const statusCancelled = Color(0xFFD8514E);
}
