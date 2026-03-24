import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';
import '../../../core/models/zone.dart';

// ── Zone list provider ───────────────────────────────────────────

final zonesProvider =
    AsyncNotifierProvider<ZonesNotifier, List<Zone>>(ZonesNotifier.new);

class ZonesNotifier extends AsyncNotifier<List<Zone>> {
  @override
  Future<List<Zone>> build() => _fetch();

  Future<List<Zone>> _fetch() async {
    final rows = await adminClient
        .from('zones')
        .select()
        .order('created_at', ascending: false);
    return rows.map((r) => Zone.fromJson(r)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addZone({
    required String name,
    required String city,
    required List<String> pincodes,
    required String zoneType,
    double? deliveryFeeOverride,
    bool isActive = true,
  }) async {
    await adminClient.from('zones').insert({
      'name': name,
      'city': city,
      'pincodes': pincodes,
      'zone_type': zoneType,
      'delivery_fee_override': deliveryFeeOverride,
      'is_active': isActive,
    });
    await refresh();
  }

  Future<void> updateZone({
    required String id,
    required String name,
    required String city,
    required List<String> pincodes,
    required String zoneType,
    double? deliveryFeeOverride,
    bool isActive = true,
  }) async {
    await adminClient.from('zones').update({
      'name': name,
      'city': city,
      'pincodes': pincodes,
      'zone_type': zoneType,
      'delivery_fee_override': deliveryFeeOverride,
      'is_active': isActive,
    }).eq('id', id);
    await refresh();
  }

  Future<void> toggleZone(String id, bool active) async {
    await adminClient
        .from('zones')
        .update({'is_active': active}).eq('id', id);
    await refresh();
  }
}
