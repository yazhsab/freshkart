import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/models/slot_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

class ScheduleState {
  final Map<DateTime, List<SlotModel>> slotsByDate;
  final DateTime selectedDate;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.slotsByDate = const {},
    DateTime? selectedDate,
    this.isLoading = false,
    this.error,
  }) : selectedDate = selectedDate ?? const _DefaultDate();

  ScheduleState copyWith({
    Map<DateTime, List<SlotModel>>? slotsByDate,
    DateTime? selectedDate,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      slotsByDate: slotsByDate ?? this.slotsByDate,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<SlotModel> get selectedDateSlots {
    final key = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return slotsByDate[key] ?? [];
  }
}

class _DefaultDate implements DateTime {
  const _DefaultDate();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final now = DateTime.now();
    return Function.apply((now as dynamic), invocation.positionalArguments);
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier() : super(ScheduleState(selectedDate: DateTime.now())) {
    fetchMonth(DateTime.now());
  }

  final _supabase = Supabase.instance.client;

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  Future<void> fetchMonth(DateTime month) async {
    state = state.copyWith(isLoading: true);
    try {
      final workerId = LocalStorage.workerId;
      if (workerId == null) return;

      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);

      final data = await _supabase
          .from('worker_slots')
          .select()
          .eq('worker_id', workerId)
          .gte('date', start.toIso8601String().split('T').first)
          .lte('date', end.toIso8601String().split('T').first)
          .order('start_time');

      final slots = (data as List).map((s) => SlotModel.fromJson(s)).toList();
      final Map<DateTime, List<SlotModel>> grouped = {};
      for (final slot in slots) {
        final key = DateTime(slot.date.year, slot.date.month, slot.date.day);
        grouped.putIfAbsent(key, () => []).add(slot);
      }

      state = state.copyWith(slotsByDate: grouped, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addSlot(DateTime date, String startTime, String endTime) async {
    final workerId = LocalStorage.workerId;
    if (workerId == null) return;

    await _supabase.from('worker_slots').insert({
      'worker_id': workerId,
      'date': date.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
    });
    await fetchMonth(date);
  }

  Future<void> addBatchSlots(
    DateTime date,
    List<Map<String, String>> timeSlots,
  ) async {
    final workerId = LocalStorage.workerId;
    if (workerId == null) return;

    final rows = timeSlots
        .map(
          (t) => {
            'worker_id': workerId,
            'date': date.toIso8601String().split('T').first,
            'start_time': t['start'],
            'end_time': t['end'],
          },
        )
        .toList();

    await _supabase.from('worker_slots').insert(rows);
    await fetchMonth(date);
  }

  Future<void> deleteSlot(String slotId) async {
    await _supabase.from('worker_slots').delete().eq('id', slotId);
    await fetchMonth(state.selectedDate);
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (ref) => ScheduleNotifier(),
);
