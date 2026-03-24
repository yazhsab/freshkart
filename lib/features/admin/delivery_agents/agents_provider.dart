import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/supabase/client.dart';
import '../../../core/utils/date_helpers.dart';

// ── Agent model with stats ──────────────────────────────────────

class DeliveryAgent {
  final Profile profile;
  final bool isOnline;
  final String? currentOrderId;
  final String? currentOrderNumber;
  final int todayDeliveries;

  const DeliveryAgent({
    required this.profile,
    this.isOnline = false,
    this.currentOrderId,
    this.currentOrderNumber,
    this.todayDeliveries = 0,
  });
}

// ── Agent location model ────────────────────────────────────────

class AgentLocation {
  final String agentId;
  final String agentName;
  final double lat;
  final double lng;
  final DateTime? updatedAt;
  final bool isOnline;

  const AgentLocation({
    required this.agentId,
    required this.agentName,
    required this.lat,
    required this.lng,
    this.updatedAt,
    this.isOnline = false,
  });

  factory AgentLocation.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return AgentLocation(
      agentId: json['agent_id'] as String,
      agentName: profile?['full_name'] as String? ?? 'Unknown',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }
}

// ── Agents list provider ────────────────────────────────────────

final agentsProvider = FutureProvider<List<DeliveryAgent>>((ref) async {
  final db = adminClient;
  final today = todayStart().toIso8601String();

  // Fetch all delivery agent profiles
  final profiles = await db
      .from('profiles')
      .select()
      .eq('role', 'delivery_agent')
      .order('created_at', ascending: false);

  final agents = <DeliveryAgent>[];

  for (final row in profiles) {
    final profile = Profile.fromJson(row as Map<String, dynamic>);

    // Get active order for this agent (picked_up status)
    final activeOrders = await db
        .from('orders')
        .select('id, order_number')
        .eq('delivery_agent_id', profile.id)
        .inFilter('status', ['picked_up', 'ready'])
        .limit(1);

    String? currentOrderId;
    String? currentOrderNumber;
    if (activeOrders.isNotEmpty) {
      currentOrderId = activeOrders[0]['id'] as String?;
      currentOrderNumber = activeOrders[0]['order_number'] as String?;
    }

    // Today deliveries count
    final deliveredResult = await db
        .from('orders')
        .select('id')
        .eq('delivery_agent_id', profile.id)
        .eq('status', 'delivered')
        .gte('delivered_at', today);

    agents.add(DeliveryAgent(
      profile: profile,
      isOnline: profile.isActive,
      currentOrderId: currentOrderId,
      currentOrderNumber: currentOrderNumber,
      todayDeliveries: (deliveredResult as List).length,
    ));
  }

  return agents;
});

// ── Online agent count ──────────────────────────────────────────

final onlineAgentCountProvider = Provider<int>((ref) {
  final agentsAsync = ref.watch(agentsProvider);
  return agentsAsync.when(
    data: (agents) => agents.where((a) => a.isOnline).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ── Real-time locations stream ──────────────────────────────────

final agentLocationsStreamProvider =
    StreamProvider<List<AgentLocation>>((ref) {
  return supabase
      .from('delivery_locations')
      .stream(primaryKey: ['agent_id'])
      .map((rows) => rows
          .map((row) => AgentLocation.fromJson(row as Map<String, dynamic>))
          .toList());
});

// ── Agent actions ───────────────────────────────────────────────

final agentActionsProvider =
    NotifierProvider<AgentActionsNotifier, void>(AgentActionsNotifier.new);

class AgentActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleAgentActive(String agentId, bool isActive) async {
    await adminClient
        .from('profiles')
        .update({'is_active': isActive}).eq('id', agentId);
    ref.invalidate(agentsProvider);
  }

  Future<void> unassignCurrentOrder(String orderId) async {
    await adminClient
        .from('orders')
        .update({'delivery_agent_id': null, 'status': 'ready'}).eq(
            'id', orderId);
    ref.invalidate(agentsProvider);
  }
}
