import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/date_util.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/features/schedule/providers/schedule_provider.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';

class AddSlotScreen extends ConsumerStatefulWidget {
  const AddSlotScreen({super.key});

  @override
  ConsumerState<AddSlotScreen> createState() => _AddSlotScreenState();
}

class _AddSlotScreenState extends ConsumerState<AddSlotScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<int> _selectedSlots = {};
  bool _isSubmitting = false;

  static const _timeSlots = [
    {'start': '08:00', 'end': '09:00', 'label': '8-9 AM'},
    {'start': '09:00', 'end': '10:00', 'label': '9-10 AM'},
    {'start': '10:00', 'end': '11:00', 'label': '10-11 AM'},
    {'start': '11:00', 'end': '12:00', 'label': '11-12 PM'},
    {'start': '12:00', 'end': '13:00', 'label': '12-1 PM'},
    {'start': '13:00', 'end': '14:00', 'label': '1-2 PM'},
    {'start': '14:00', 'end': '15:00', 'label': '2-3 PM'},
    {'start': '15:00', 'end': '16:00', 'label': '3-4 PM'},
    {'start': '16:00', 'end': '17:00', 'label': '4-5 PM'},
    {'start': '17:00', 'end': '18:00', 'label': '5-6 PM'},
    {'start': '18:00', 'end': '19:00', 'label': '6-7 PM'},
    {'start': '19:00', 'end': '20:00', 'label': '7-8 PM'},
  ];

  Future<void> _submit() async {
    if (_selectedSlots.isEmpty) {
      context.showSnackBar('Select at least one slot', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final slots = _selectedSlots
          .map(
            (i) => {
              'start': _timeSlots[i]['start']!,
              'end': _timeSlots[i]['end']!,
            },
          )
          .toList();
      await ref
          .read(scheduleProvider.notifier)
          .addBatchSlots(_selectedDate, slots);
      if (mounted) {
        context.showSnackBar('${slots.length} slots added!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      14,
      (i) => DateTime.now().add(Duration(days: i)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Availability')),
      body: Column(
        children: [
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = date.dateOnly == _selectedDate.dateOnly;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? WorkerColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? WorkerColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateUtil.formatDateShort(date).split(' ').first,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          DateUtil.formatDateShort(date).split(' ').last,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Select Time Slots',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedSlots.length == _timeSlots.length) {
                        _selectedSlots.clear();
                      } else {
                        _selectedSlots.addAll(
                          List.generate(_timeSlots.length, (i) => i),
                        );
                      }
                    });
                  },
                  child: Text(
                    _selectedSlots.length == _timeSlots.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedSlots.contains(index);
                return GestureDetector(
                  onTap: () => setState(() {
                    isSelected
                        ? _selectedSlots.remove(index)
                        : _selectedSlots.add(index);
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? WorkerColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? WorkerColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _timeSlots[index]['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Add ${_selectedSlots.length} Slots',
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}
