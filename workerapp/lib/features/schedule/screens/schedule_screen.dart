import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/schedule/providers/schedule_provider.dart';
import 'package:freshkart_worker/features/schedule/widgets/slot_card.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/empty_state_widget.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed('add-slot'),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: state.selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
            onDaySelected: (selected, focused) => notifier.selectDate(selected),
            onPageChanged: (focused) => notifier.fetchMonth(focused),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: WorkerColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: WorkerColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: WorkerColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return state.slotsByDate[key] ?? [];
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Slots for ${state.selectedDate.day}/${state.selectedDate.month}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.selectedDateSlots.length} slots',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.selectedDateSlots.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.event_available,
                    title: 'No slots for this day',
                    actionLabel: 'Add Slot',
                    onAction: () => context.pushNamed('add-slot'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.selectedDateSlots.length,
                    itemBuilder: (context, index) {
                      final slot = state.selectedDateSlots[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SlotCard(
                          slot: slot,
                          onDelete: () => notifier.deleteSlot(slot.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
