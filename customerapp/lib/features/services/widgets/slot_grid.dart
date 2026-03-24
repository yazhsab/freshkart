import 'package:flutter/material.dart';

class SlotGrid extends StatelessWidget {
  final List<String> availableSlots;
  final List<String> bookedSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSelect;

  const SlotGrid({
    super.key,
    required this.availableSlots,
    required this.bookedSlots,
    this.selectedSlot,
    required this.onSelect,
  });

  /// Default time slots from 9 AM to 5 PM.
  static const List<String> _defaultSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  String _formatSlotLabel(String slot) {
    final parts = slot.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${parts.length > 1 ? parts[1] : "00"} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    // Merge all known slots for display.
    final allSlots = <String>{
      ..._defaultSlots,
      ...availableSlots,
      ...bookedSlots,
    }.toList()..sort();

    if (allSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No slots available for this date',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: allSlots.map((slot) {
        final isBooked = bookedSlots.contains(slot);
        final isAvailable = availableSlots.contains(slot);
        final isSelected = selectedSlot == slot;

        Color backgroundColor;
        Color borderColor;
        Color textColor;
        bool enabled;

        if (isSelected) {
          backgroundColor = Colors.amber[700]!;
          borderColor = Colors.amber[700]!;
          textColor = Colors.white;
          enabled = true;
        } else if (isBooked) {
          backgroundColor = Colors.grey[200]!;
          borderColor = Colors.grey[300]!;
          textColor = Colors.grey[500]!;
          enabled = false;
        } else if (isAvailable) {
          backgroundColor = Colors.white;
          borderColor = Colors.amber[400]!;
          textColor = Colors.amber[800]!;
          enabled = true;
        } else {
          backgroundColor = Colors.grey[100]!;
          borderColor = Colors.grey[300]!;
          textColor = Colors.grey[400]!;
          enabled = false;
        }

        return GestureDetector(
          onTap: enabled ? () => onSelect(slot) : null,
          child: Container(
            width: 95,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Column(
              children: [
                Text(
                  _formatSlotLabel(slot),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (isBooked)
                  Text(
                    'Booked',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
