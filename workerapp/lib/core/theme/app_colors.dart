import 'package:flutter/material.dart';

class WorkerColors {
  WorkerColors._();
  static const primary = Color(0xFFDC5C2F);
  static const primaryLight = Color(0xFFF29A53);
  static const primaryDark = Color(0xFFA53C1A);
  static const primaryBg = Color(0xFFFFEEE2);
  static const available = Color(0xFF43A047);
  static const unavailable = Color(0xFF757575);
  static const busy = Color(0xFFD94A45);
  static const jobPending = Color(0xFF9E9E9E);
  static const jobAssigned = Color(0xFF1976D2);
  static const jobConfirmed = Color(0xFF7B1FA2);
  static const jobOnWay = Color(0xFFF29A53);
  static const jobInProgress = Color(0xFFDC5C2F);
  static const jobCompleted = Color(0xFF2E7D32);
  static const jobCancelled = Color(0xFFD94A45);
  static const jobDisputed = Color(0xFF880E4F);
  static const earningsOrange = Color(0xFFDC5C2F);
  static const earningsGreen = Color(0xFF2E7D32);
  static const bonusGold = Color(0xFFF0BC4A);
  static const commissionRed = Color(0xFFD94A45);
  static const bgvPending = Color(0xFF9E9E9E);
  static const bgvProgress = Color(0xFF1976D2);
  static const bgvApproved = Color(0xFF2E7D32);
  static const bgvRejected = Color(0xFFD94A45);
  static const background = Color(0xFFFFF6EF);
  static const surface = Color(0xFFFFFCF8);
  static const textPrimary = Color(0xFF211913);
  static const textSecondary = Color(0xFF796A5E);
  static const divider = Color(0xFFEEDFD5);

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return jobPending;
      case 'assigned':
        return jobAssigned;
      case 'confirmed':
        return jobConfirmed;
      case 'worker_on_way':
        return jobOnWay;
      case 'in_progress':
        return jobInProgress;
      case 'completed':
        return jobCompleted;
      case 'cancelled':
        return jobCancelled;
      case 'disputed':
        return jobDisputed;
      default:
        return jobPending;
    }
  }

  static Color bgvColor(String status) {
    switch (status) {
      case 'pending':
        return bgvPending;
      case 'in_progress':
        return bgvProgress;
      case 'approved':
        return bgvApproved;
      case 'rejected':
        return bgvRejected;
      default:
        return bgvPending;
    }
  }
}
