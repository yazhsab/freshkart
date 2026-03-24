import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_customer/features/services/providers/services_provider.dart';
import 'package:freshkart_customer/features/services/widgets/slot_grid.dart';

/// Result returned when a slot is picked.
class SlotPickerResult {
  final DateTime date;
  final String slotStart;
  final String slotEnd;

  const SlotPickerResult({
    required this.date,
    required this.slotStart,
    required this.slotEnd,
  });
}

/// Standalone slot picker screen. Returns [SlotPickerResult] on pop.
class SlotPickerScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const SlotPickerScreen({super.key, required this.categoryId});

  @override
  ConsumerState<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends ConsumerState<SlotPickerScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final next7Days = List.generate(7, (i) => today.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a Slot'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedDate != null && _selectedSlot != null)
                  ? () {
                      final parts = _selectedSlot!.split(':');
                      final hour = int.parse(parts[0]);
                      final endHour = hour + 1;
                      final end =
                          '${endHour.toString().padLeft(2, '0')}:${parts[1]}';

                      Navigator.of(context).pop(
                        SlotPickerResult(
                          date: _selectedDate!,
                          slotStart: _selectedSlot!,
                          slotEnd: end,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Slot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select a date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Date chips
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: next7Days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final date = next7Days[index];
                final isSelected =
                    _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;
                final isToday = index == 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null;
                    });
                  },
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber[700] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.amber[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday ? 'Today' : DateFormat('EEE').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Time slots
          if (_selectedDate != null) ...[
            const Text(
              'Select a time slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSlots(),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Select a date to see available slots',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlots() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final slotsAsync = ref.watch(
      availableSlotsProvider((categoryId: widget.categoryId, date: dateStr)),
    );

    return slotsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Error loading slots: $e'),
      ),
      data: (slotData) => SlotGrid(
        availableSlots: slotData.availableSlots,
        bookedSlots: slotData.bookedSlots,
        selectedSlot: _selectedSlot,
        onSelect: (slot) {
          setState(() => _selectedSlot = slot);
        },
      ),
    );
  }
}
