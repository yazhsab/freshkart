import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/models/notification_model.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

// ── Notifications Provider ──

final notificationsProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      final notifier = NotificationsNotifier(ApiClient());
      ref.onDispose(() => notifier.dispose());
      return notifier;
    });

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiClient _api;
  RealtimeChannel? _channel;

  NotificationsNotifier(this._api) : super(const AsyncLoading()) {
    fetchNotifications();
    _subscribeRealtime();
  }

  Future<void> fetchNotifications() async {
    try {
      state = const AsyncLoading();
      final response = await _api.get('/api/v1/notifications');
      final data = response.data as Map<String, dynamic>;
      final list = (data['notifications'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _subscribeRealtime() {
    final userId = LocalStorage.getString(LocalStorage.kUserId);
    if (userId == null) return;

    _channel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotification = NotificationModel.fromJson(
              payload.newRecord,
            );
            final current = state.valueOrNull ?? [];
            state = AsyncData([newNotification, ...current]);
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.put('/api/v1/notifications/$id', data: {'is_read': true});
      final current = state.valueOrNull ?? [];
      state = AsyncData(
        current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.put('/api/v1/notifications/mark-all-read');
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
    } catch (_) {
      // Silently fail
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ── Notifications Screen ──

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load notifications',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref
                    .read(notificationsProvider.notifier)
                    .fetchNotifications(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  Color _dotColor() {
    switch (notification.type) {
      case 'grocery':
      case 'order':
        return AppColors.primaryGreen;
      case 'service':
      case 'booking':
        return AppColors.primaryAmber;
      case 'payment':
        return AppColors.info;
      default:
        return AppColors.textHint;
    }
  }

  String _timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(notification.sentAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${notification.sentAt.day}/${notification.sentAt.month}/${notification.sentAt.year}';
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Navigate to relevant screen
    if (notification.refType != null && notification.refId != null) {
      switch (notification.refType) {
        case 'order':
          context.push('/orders/${notification.refId}');
          break;
        case 'booking':
          context.push('/bookings/${notification.refId}');
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: notification.isRead ? Colors.grey.shade50 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: _dotColor(), shape: BoxShape.circle),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _timeAgo(),
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
        onTap: () => _onTap(context, ref),
      ),
    );
  }
}
