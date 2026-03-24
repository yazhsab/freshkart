import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class AvailabilityToggleCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onToggle;

  const AvailabilityToggleCard({
    super.key,
    required this.isAvailable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
              : [Colors.grey.shade600, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? Colors.green : Colors.grey).withValues(
              alpha: 0.3,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'You\'re Online' : 'You\'re Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAvailable
                      ? 'புதிய புக்கிங்குகள் வரும்'
                      : 'ஆன்லைனில் வாருங்கள்',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.3,
            child: Switch(
              value: isAvailable,
              onChanged: onToggle,
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
