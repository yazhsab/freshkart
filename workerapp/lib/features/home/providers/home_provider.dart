import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/models/worker_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

class HomeState {
  final WorkerModel? worker;
  final List<BookingModel> todayBookings;
  final List<BookingModel> upcomingBookings;
  final BookingModel? activeBooking;
  final double todayEarnings;
  final double weekEarnings;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.worker,
    this.todayBookings = const [],
    this.upcomingBookings = const [],
    this.activeBooking,
    this.todayEarnings = 0,
    this.weekEarnings = 0,
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    WorkerModel? worker,
    List<BookingModel>? todayBookings,
    List<BookingModel>? upcomingBookings,
    BookingModel? activeBooking,
    double? todayEarnings,
    double? weekEarnings,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      worker: worker ?? this.worker,
      todayBookings: todayBookings ?? this.todayBookings,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      activeBooking: activeBooking ?? this.activeBooking,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      weekEarnings: weekEarnings ?? this.weekEarnings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState()) {
    loadData();
  }

  final _supabase = Supabase.instance.client;
  StreamSubscription? _bookingSub;

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final workerId = LocalStorage.workerId;
      if (workerId == null) return;

      final workerData =
          await _supabase.from('workers').select().eq('id', workerId).single();
      final worker = WorkerModel.fromJson(workerData);

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayBookingsData = await _supabase
          .from('bookings')
          .select()
          .eq('worker_id', workerId)
          .eq('scheduled_date', todayStr)
          .order('slot_start');

      final upcomingData = await _supabase
          .from('bookings')
          .select()
          .eq('worker_id', workerId)
          .inFilter('status', ['assigned', 'confirmed'])
          .gte('scheduled_date', todayStr)
          .order('scheduled_date')
          .limit(5);

      final todayBookings = (todayBookingsData as List)
          .map((b) => BookingModel.fromJson(b))
          .toList();
      final upcomingBookings =
          (upcomingData as List).map((b) => BookingModel.fromJson(b)).toList();

      BookingModel? activeBooking;
      final activeId = LocalStorage.activeBookingId;
      if (activeId != null) {
        final activeData = await _supabase
            .from('bookings')
            .select()
            .eq('id', activeId)
            .maybeSingle();
        if (activeData != null)
          activeBooking = BookingModel.fromJson(activeData);
      }

      final completedToday = todayBookings.where((b) => b.isCompleted);
      final todayEarnings = completedToday.fold<double>(
        0,
        (sum, b) => sum + (b.workerEarnings ?? 0),
      );

      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStr =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      final weekData = await _supabase
          .from('bookings')
          .select('worker_earnings')
          .eq('worker_id', workerId)
          .eq('status', 'completed')
          .gte('scheduled_date', weekStr);
      final weekEarnings = (weekData as List).fold<double>(
        0,
        (sum, b) => sum + ((b['worker_earnings'] as num?)?.toDouble() ?? 0),
      );

      state = state.copyWith(
        worker: worker,
        todayBookings: todayBookings,
        upcomingBookings: upcomingBookings,
        activeBooking: activeBooking,
        todayEarnings: todayEarnings,
        weekEarnings: weekEarnings,
        isLoading: false,
      );

      _listenForBookings(workerId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _listenForBookings(String workerId) {
    _bookingSub?.cancel();
    _bookingSub = _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('worker_id', workerId)
        .listen((_) => loadData());
  }

  Future<void> toggleAvailability(bool value) async {
    final workerId = LocalStorage.workerId;
    if (workerId == null) return;
    await _supabase
        .from('workers')
        .update({'is_available': value}).eq('id', workerId);
    LocalStorage.isAvailable = value;
    state = state.copyWith(worker: state.worker?.copyWith(isAvailable: value));
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    super.dispose();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);
