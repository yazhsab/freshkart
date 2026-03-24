import 'package:flutter/material.dart';

class DeliveryColors {
  DeliveryColors._();

  // Primary Teal
  static const Color primary = Color(0xFF0B6C63);
  static const Color primaryLight = Color(0xFF34A79D);
  static const Color primaryDark = Color(0xFF084942);
  static const Color primaryBg = Color(0xFFE5F5F2);

  // Agent Status
  static const Color online = Color(0xFF43A047);
  static const Color offline = Color(0xFF757575);
  static const Color busy = Color(0xFFF29A3F);

  // Delivery Steps
  static const Color stepPending = Color(0xFF9E9E9E);
  static const Color stepActive = Color(0xFF0B6C63);
  static const Color stepPickup = Color(0xFFF29A3F);
  static const Color stepDropoff = Color(0xFF43A047);
  static const Color stepDone = Color(0xFF2E7D32);

  // Earnings
  static const Color earningsTeal = Color(0xFF138679);
  static const Color bonusGold = Color(0xFFF0BC4A);

  // Alerts
  static const Color newOrder = Color(0xFFD94B46);
  static const Color warning = Color(0xFFF29A3F);

  // Surfaces
  static const Color background = Color(0xFFF1F7F5);
  static const Color surface = Color(0xFFFCFFFE);
  static const Color textPrimary = Color(0xFF132220);
  static const Color textSecondary = Color(0xFF65726F);
  static const Color divider = Color(0xFFDCE6E3);

  // Status color helper
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return online;
      case 'offline':
        return offline;
      case 'busy':
        return busy;
      default:
        return offline;
    }
  }

  // Delivery step color helper
  static Color stepColor(String step) {
    switch (step.toLowerCase()) {
      case 'pending':
        return stepPending;
      case 'active':
      case 'assigned':
        return stepActive;
      case 'pickup':
      case 'picked_up':
        return stepPickup;
      case 'dropoff':
      case 'in_transit':
        return stepDropoff;
      case 'done':
      case 'delivered':
        return stepDone;
      default:
        return stepPending;
    }
  }
}
