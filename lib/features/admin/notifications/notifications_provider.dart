import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── Notification history ─────────────────────────────────────────

class NotificationEntry {
  final String id;
  final String title;
  final String body;
  final String audience;
  final String channel;
  final int? reachCount;
  final String status;
  final DateTime? createdAt;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.channel,
    this.reachCount,
    required this.status,
    this.createdAt,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      audience: json['audience'] as String? ?? 'all',
      channel: json['channel'] as String? ?? 'push',
      reachCount: json['reach_count'] as int?,
      status: json['status'] as String? ?? 'sent',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

// ── Notifications Notifier ───────────────────────────────────────

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier,
    List<NotificationEntry>>(NotificationsNotifier.new);

class NotificationsNotifier extends AsyncNotifier<List<NotificationEntry>> {
  @override
  Future<List<NotificationEntry>> build() => _fetchHistory();

  Future<List<NotificationEntry>> _fetchHistory() async {
    final rows = await adminClient
        .from('admin_notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map((r) => NotificationEntry.fromJson(r)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchHistory);
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String audience,
    required String channel,
  }) async {
    // Determine reach estimate
    int reachCount = 0;
    if (audience == 'all') {
      final result = await adminClient
          .from('profiles')
          .select('id')
          .eq('role', 'customer')
          .eq('is_active', true);
      reachCount = (result as List).length;
    } else if (audience == 'customers') {
      final result = await adminClient
          .from('profiles')
          .select('id')
          .eq('role', 'customer')
          .eq('is_active', true);
      reachCount = (result as List).length;
    } else if (audience == 'vendors') {
      final result = await adminClient
          .from('vendors')
          .select('id')
          .eq('is_active', true)
          .eq('is_approved', true);
      reachCount = (result as List).length;
    } else if (audience == 'workers') {
      final result = await adminClient
          .from('workers')
          .select('id')
          .eq('is_active', true);
      reachCount = (result as List).length;
    }

    // Log to admin_notifications table
    await adminClient.from('admin_notifications').insert({
      'title': title,
      'body': body,
      'audience': audience,
      'channel': channel,
      'reach_count': reachCount,
      'status': 'sent',
    });

    // Placeholder: In production, this would call a backend endpoint
    // to actually dispatch push notifications / SMS via FCM / SMS gateway.
    // e.g., await http.post(Uri.parse('$backendUrl/api/send-notification'), ...)

    await refresh();
  }
}

// ── Reach estimate provider ──────────────────────────────────────

final reachEstimateProvider =
    FutureProvider.family<int, String>((ref, audience) async {
  if (audience == 'all') {
    final result = await adminClient
        .from('profiles')
        .select('id')
        .eq('is_active', true);
    return (result as List).length;
  } else if (audience == 'customers') {
    final result = await adminClient
        .from('profiles')
        .select('id')
        .eq('role', 'customer')
        .eq('is_active', true);
    return (result as List).length;
  } else if (audience == 'vendors') {
    final result = await adminClient
        .from('vendors')
        .select('id')
        .eq('is_active', true)
        .eq('is_approved', true);
    return (result as List).length;
  } else if (audience == 'workers') {
    final result = await adminClient
        .from('workers')
        .select('id')
        .eq('is_active', true);
    return (result as List).length;
  }
  return 0;
});
