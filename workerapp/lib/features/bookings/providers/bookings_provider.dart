import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

class BookingsState {
  final List<BookingModel> upcoming;
  final List<BookingModel> active;
  final List<BookingModel> past;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.upcoming = const [],
    this.active = const [],
    this.past = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<BookingModel>? upcoming,
    List<BookingModel>? active,
    List<BookingModel>? past,
    bool? isLoading,
    String? error,
  }) {
    return BookingsState(
      upcoming: upcoming ?? this.upcoming,
      active: active ?? this.active,
      past: past ?? this.past,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  BookingsNotifier() : super(const BookingsState()) {
    fetch();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final workerId = LocalStorage.workerId;
      if (workerId == null) return;

      final data = await _supabase
          .from('bookings')
          .select()
          .eq('worker_id', workerId)
          .order('scheduled_date', ascending: false);
      final bookings =
          (data as List).map((b) => BookingModel.fromJson(b)).toList();

      state = state.copyWith(
        upcoming: bookings.where((b) => b.isUpcoming).toList(),
        active: bookings.where((b) => b.isActive).toList(),
        past: bookings.where((b) => b.isPast).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'confirmed'}).eq('id', bookingId);
    await fetch();
  }

  Future<void> declineBooking(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'pending', 'worker_id': null}).eq('id', bookingId);
    await fetch();
  }

  Future<void> markOnWay(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'on_way'}).eq('id', bookingId);
    await fetch();
  }

  Future<void> checkin(String bookingId, String otp) async {
    final booking = await _supabase
        .from('bookings')
        .select('checkin_otp')
        .eq('id', bookingId)
        .single();
    if (booking['checkin_otp'] != otp) throw Exception('Invalid OTP');
    await _supabase.from('bookings').update({
      'status': 'in_progress',
      'checkin_time': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
    LocalStorage.activeBookingId = bookingId;
    LocalStorage.jobStartTime = DateTime.now().toIso8601String();
    await fetch();
  }

  Future<void> completeBooking(
    String bookingId,
    Map<String, dynamic> reportData,
  ) async {
    await _supabase.from('bookings').update({
      'status': 'completed',
      'checkout_time': DateTime.now().toIso8601String(),
      ...reportData,
    }).eq('id', bookingId);
    LocalStorage.activeBookingId = null;
    LocalStorage.jobStartTime = null;
    await fetch();
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>(
  (ref) => BookingsNotifier(),
);
