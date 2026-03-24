import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/booking_model.dart';

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>(
  (ref) => BookingsNotifier(ApiClient()),
);

class BookingsState {
  final List<BookingModel> upcomingBookings;
  final List<BookingModel> pastBookings;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.upcomingBookings = const [],
    this.pastBookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<BookingModel>? upcomingBookings,
    List<BookingModel>? pastBookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingsState(
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      pastBookings: pastBookings ?? this.pastBookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final ApiClient _api;

  BookingsNotifier(this._api) : super(const BookingsState());

  /// Statuses that belong to "upcoming" (active) bookings.
  static const _upcomingStatuses = {
    'pending',
    'assigned',
    'confirmed',
    'worker_on_way',
    'in_progress',
  };

  /// Fetches all bookings for the current user and splits them
  /// into upcoming and past lists.
  Future<void> fetchBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get(ApiEndpoints.myBookings);
      final data = response.data as Map<String, dynamic>;
      final list = data['bookings'] as List<dynamic>;
      final bookings = list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final upcoming =
          bookings.where((b) => _upcomingStatuses.contains(b.status)).toList()
            ..sort((a, b) => a.slotDate.compareTo(b.slotDate));

      final past =
          bookings.where((b) => !_upcomingStatuses.contains(b.status)).toList()
            ..sort((a, b) => b.slotDate.compareTo(a.slotDate));

      state = state.copyWith(
        upcomingBookings: upcoming,
        pastBookings: past,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cancels a booking by ID via POST /bookings/{id}/cancel.
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _api.post(ApiEndpoints.cancelBooking(bookingId));
      // Refresh bookings after cancellation.
      await fetchBookings();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
