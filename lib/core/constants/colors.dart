import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F7A5C);
  static const Color primaryDark = Color(0xFF082F24);
  static const Color sidebar = Color(0xFF10231C);
  static const Color secondary = Color(0xFFF0A33A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6F1);
  static const Color surfaceAlt = Color(0xFFF0F5EF);
  static const Color error = Color(0xFFD8514E);
  static const Color textPrimary = Color(0xFF15231C);
  static const Color textSecondary = Color(0xFF677468);
  static const Color textHint = Color(0xFF97A49A);
  static const Color border = Color(0xFFD9E2DA);
  static const Color divider = Color(0xFFD9E2DA);
  static const Color spotlight = Color(0xFFE3F7EE);
  static const Color spotlightAmber = Color(0xFFFFE8C9);
  static const Color sidebarStroke = Color(0x1FFFFFFF);
  static const Color shadow = Color(0x140B2118);

  // Order status
  static const Color statusPending = Color(0xFF9E9E9E);
  static const Color statusConfirmed = Color(0xFF2E84D8);
  static const Color statusPacking = Color(0xFF6E76D9);
  static const Color statusReady = Color(0xFFF29B38);
  static const Color statusPickedUp = Color(0xFFEC7A31);
  static const Color statusDelivered = Color(0xFF26A269);
  static const Color statusCancelled = Color(0xFFD8514E);
  static const Color statusRefunded = Color(0xFFC35CC5);

  // Booking status
  static const Color statusAssigned = Color(0xFF2E84D8);
  static const Color statusWorkerOnWay = Color(0xFFF29B38);
  static const Color statusInProgress = Color(0xFFEC7A31);
  static const Color statusCompleted = Color(0xFF26A269);
  static const Color statusDisputed = Color(0xFFD8514E);

  // BGV
  static const Color bgvPending = Color(0xFF9E9E9E);
  static const Color bgvInProgress = Color(0xFF2E84D8);
  static const Color bgvApproved = Color(0xFF26A269);
  static const Color bgvRejected = Color(0xFFD8514E);

  // Payment
  static const Color paymentPending = Color(0xFFF29B38);
  static const Color paymentPaid = Color(0xFF26A269);
  static const Color paymentFailed = Color(0xFFD8514E);
  static const Color paymentRefundedColor = Color(0xFF6E76D9);
}
