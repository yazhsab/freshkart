import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_category.dart';
import '../../../core/models/worker.dart';
import '../../../core/supabase/client.dart';

// ── Show only active toggle ─────────────────────────────────────

final showOnlyActiveServicesProvider =
    NotifierProvider<ShowOnlyActiveServicesNotifier, bool>(
  ShowOnlyActiveServicesNotifier.new,
);

class ShowOnlyActiveServicesNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

// ── Service catalog list ────────────────────────────────────────

final serviceCatalogProvider =
    FutureProvider<List<ServiceCategory>>((ref) async {
  final showOnlyActive = ref.watch(showOnlyActiveServicesProvider);

  var query = adminClient.from('service_categories').select();

  if (showOnlyActive) {
    query = query.eq('is_active', true);
  }

  final rows = await query.order('sort_order');

  return rows
      .map((row) => ServiceCategory.fromJson(row as Map<String, dynamic>))
      .toList();
});

// ── Workers per service ─────────────────────────────────────────

final workersPerServiceProvider =
    FutureProvider.family<List<Worker>, String>((ref, serviceId) async {
  final rows = await adminClient
      .from('workers')
      .select('*, profiles(*)')
      .contains('service_category_ids', [serviceId])
      .order('created_at', ascending: false);

  return rows
      .map((row) => Worker.fromJson(row as Map<String, dynamic>))
      .toList();
});

// ── Service catalog actions ─────────────────────────────────────

final serviceCatalogActionsProvider =
    NotifierProvider<ServiceCatalogActionsNotifier, void>(
  ServiceCatalogActionsNotifier.new,
);

class ServiceCatalogActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addService(Map<String, dynamic> data) async {
    await adminClient.from('service_categories').insert(data);
    ref.invalidate(serviceCatalogProvider);
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await adminClient.from('service_categories').update(data).eq('id', id);
    ref.invalidate(serviceCatalogProvider);
  }

  Future<void> toggleService(String id, bool isActive) async {
    await adminClient
        .from('service_categories')
        .update({'is_active': isActive}).eq('id', id);
    ref.invalidate(serviceCatalogProvider);
  }

  Future<void> deleteService(String id) async {
    await adminClient.from('service_categories').delete().eq('id', id);
    ref.invalidate(serviceCatalogProvider);
  }
}
