import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/service_category_model.dart';
import 'package:freshkart_customer/core/models/worker_model.dart';

/// Fetches all active service categories from GET /services.
final serviceCategoriesProvider = FutureProvider<List<ServiceCategoryModel>>((
  ref,
) async {
  final response = await ApiClient().get(ApiEndpoints.serviceCategories);
  final data = response.data as Map<String, dynamic>;
  final list = data['categories'] as List<dynamic>;
  return list
      .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
      .where((c) => c.isActive)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Fetches available workers for a given service category.
/// Usage: ref.watch(workersProvider(categoryId))
final workersProvider = FutureProvider.family<List<WorkerModel>, String>((
  ref,
  categoryId,
) async {
  final response = await ApiClient().get(
    ApiEndpoints.availableWorkers(categoryId),
  );
  final data = response.data as Map<String, dynamic>;
  final list = data['workers'] as List<dynamic>;
  return list
      .map((e) => WorkerModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Parameter record for available slots lookup.
typedef SlotParams = ({String categoryId, String date});

/// Fetches available time slots for a category on a given date.
/// Usage: ref.watch(availableSlotsProvider((categoryId: '...', date: '2026-03-16')))
final availableSlotsProvider = FutureProvider.family<SlotData, SlotParams>((
  ref,
  params,
) async {
  final response = await ApiClient().get(
    ApiEndpoints.availableSlots(params.categoryId, params.date),
  );
  final data = response.data as Map<String, dynamic>;
  final available =
      (data['available_slots'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [];
  final booked =
      (data['booked_slots'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [];
  return SlotData(availableSlots: available, bookedSlots: booked);
});

/// Holds the available and booked slots returned from the API.
class SlotData {
  final List<String> availableSlots;
  final List<String> bookedSlots;

  const SlotData({required this.availableSlots, required this.bookedSlots});
}
