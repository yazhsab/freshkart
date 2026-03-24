import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/address_model.dart';
import 'package:freshkart_customer/core/models/booking_model.dart';

/// Manages the multi-step booking form state.
final bookingFormProvider =
    StateNotifierProvider<BookingFormNotifier, BookingFormState>(
      (ref) => BookingFormNotifier(ApiClient()),
    );

class BookingFormState {
  final String? serviceCategoryId;
  final AddressModel? serviceAddress;
  final DateTime? slotDate;
  final String? slotStart;
  final String? slotEnd;
  final String? customerNotes;
  final String paymentMethod;
  final bool isSubmitting;
  final String? error;
  final BookingModel? createdBooking;

  const BookingFormState({
    this.serviceCategoryId,
    this.serviceAddress,
    this.slotDate,
    this.slotStart,
    this.slotEnd,
    this.customerNotes,
    this.paymentMethod = 'cash',
    this.isSubmitting = false,
    this.error,
    this.createdBooking,
  });

  BookingFormState copyWith({
    String? serviceCategoryId,
    AddressModel? serviceAddress,
    DateTime? slotDate,
    String? slotStart,
    String? slotEnd,
    String? customerNotes,
    String? paymentMethod,
    bool? isSubmitting,
    String? error,
    BookingModel? createdBooking,
  }) {
    return BookingFormState(
      serviceCategoryId: serviceCategoryId ?? this.serviceCategoryId,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      slotDate: slotDate ?? this.slotDate,
      slotStart: slotStart ?? this.slotStart,
      slotEnd: slotEnd ?? this.slotEnd,
      customerNotes: customerNotes ?? this.customerNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }
}

class BookingFormNotifier extends StateNotifier<BookingFormState> {
  final ApiClient _api;

  BookingFormNotifier(this._api) : super(const BookingFormState());

  /// Sets the service category for this booking.
  void setServiceCategory(String categoryId) {
    state = state.copyWith(serviceCategoryId: categoryId);
  }

  /// Sets the service address.
  void setAddress(AddressModel address) {
    state = state.copyWith(serviceAddress: address);
  }

  /// Sets the selected date and time slot.
  void setSlot({
    required DateTime date,
    required String start,
    required String end,
  }) {
    state = state.copyWith(slotDate: date, slotStart: start, slotEnd: end);
  }

  /// Sets customer notes for the worker.
  void setNotes(String notes) {
    state = state.copyWith(customerNotes: notes);
  }

  /// Sets the payment method (cash, upi, card).
  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Submits the booking to POST /bookings and returns the created booking.
  Future<BookingModel?> submitBooking() async {
    if (state.isSubmitting) return null;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final response = await _api.post(
        ApiEndpoints.createBooking,
        data: {
          'service_category_id': state.serviceCategoryId,
          'slot_date': state.slotDate?.toIso8601String().split('T').first,
          'slot_start': state.slotStart,
          'slot_end': state.slotEnd,
          'service_address': state.serviceAddress?.toJson(),
          'customer_notes': state.customerNotes,
          'payment_method': state.paymentMethod,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final booking = BookingModel.fromJson(
        data['booking'] as Map<String, dynamic>,
      );

      state = state.copyWith(isSubmitting: false, createdBooking: booking);
      return booking;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  /// Resets the form to its initial state.
  void reset() {
    state = const BookingFormState();
  }
}
