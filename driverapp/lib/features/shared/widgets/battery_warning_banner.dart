import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class BatteryWarningBanner extends StatelessWidget {
  final int batteryLevel;

  const BatteryWarningBanner({super.key, required this.batteryLevel});

  bool get _isCritical => batteryLevel < 10;
  bool get _isLow => batteryLevel < 20;
  bool get _shouldShow => _isLow;

  Color get _backgroundColor =>
      _isCritical ? DeliveryColors.newOrder : DeliveryColors.warning;

  String get _message => _isCritical
      ? '\uD83D\uDD34 Critical battery! Please charge now'
      : '\u26A0 Battery at $batteryLevel% \u2014 charge soon';

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _backgroundColor,
      child: Row(
        children: [
          Icon(
            _isCritical
                ? Icons.battery_alert_rounded
                : Icons.battery_2_bar_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
