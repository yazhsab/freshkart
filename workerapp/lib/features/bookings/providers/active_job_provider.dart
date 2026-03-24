import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

class ActiveJobState {
  final Duration elapsed;
  final List<bool> checklist;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String notes;
  final double additionalCharges;
  final String? additionalChargesNote;
  final bool isOvertime;

  const ActiveJobState({
    this.elapsed = Duration.zero,
    this.checklist = const [],
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.notes = '',
    this.additionalCharges = 0,
    this.additionalChargesNote,
    this.isOvertime = false,
  });

  ActiveJobState copyWith({
    Duration? elapsed,
    List<bool>? checklist,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? notes,
    double? additionalCharges,
    String? additionalChargesNote,
    bool? isOvertime,
  }) {
    return ActiveJobState(
      elapsed: elapsed ?? this.elapsed,
      checklist: checklist ?? this.checklist,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      notes: notes ?? this.notes,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      additionalChargesNote:
          additionalChargesNote ?? this.additionalChargesNote,
      isOvertime: isOvertime ?? this.isOvertime,
    );
  }

  int get checklistProgress =>
      checklist.isEmpty ? 0 : checklist.where((c) => c).length;
  double get checklistPercent =>
      checklist.isEmpty ? 0 : checklistProgress / checklist.length;
}

class ActiveJobNotifier extends StateNotifier<ActiveJobState> {
  ActiveJobNotifier(int checklistLength)
    : super(ActiveJobState(checklist: List.filled(checklistLength, false))) {
    _startTimer();
  }

  Timer? _timer;

  void _startTimer() {
    final startStr = LocalStorage.jobStartTime;
    if (startStr != null) {
      final startTime = DateTime.parse(startStr);
      state = state.copyWith(elapsed: DateTime.now().difference(startTime));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startStr = LocalStorage.jobStartTime;
      if (startStr != null) {
        final startTime = DateTime.parse(startStr);
        final elapsed = DateTime.now().difference(startTime);
        state = state.copyWith(
          elapsed: elapsed,
          isOvertime: elapsed.inMinutes > 120,
        );
      }
    });
  }

  void toggleChecklistItem(int index) {
    final updated = List<bool>.from(state.checklist);
    updated[index] = !updated[index];
    state = state.copyWith(checklist: updated);
  }

  void addBeforePhoto(String url) {
    state = state.copyWith(beforePhotos: [...state.beforePhotos, url]);
  }

  void addAfterPhoto(String url) {
    state = state.copyWith(afterPhotos: [...state.afterPhotos, url]);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void updateAdditionalCharges(double amount, String? note) {
    state = state.copyWith(
      additionalCharges: amount,
      additionalChargesNote: note,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeJobProvider =
    StateNotifierProvider.family<ActiveJobNotifier, ActiveJobState, int>(
      (ref, checklistLength) => ActiveJobNotifier(checklistLength),
    );
