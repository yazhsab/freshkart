import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';

/// Handles navigation based on notification payload data.
///
/// Expects a `Map<String, dynamic>` with at least a `type` key.
/// Optional keys: `order_id`, `booking_id`.
class NotificationHandler {
  NotificationHandler._();

  /// Navigates to the appropriate screen based on [data].
  ///
  /// [router] is the app-level [GoRouter] instance so this helper
  /// remains stateless and testable.
  static void handleNotificationTap(
    GoRouter router,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;
    if (type == null) {
      debugPrint('NotificationHandler: No "type" in notification data.');
      return;
    }

    switch (type) {
      case 'new_order':
      case 'order_update':
        final orderId = data['order_id'] as String?;
        if (orderId != null) {
          router.goNamed(
            RouteNames.orderDetail,
            pathParameters: {'id': orderId},
          );
        } else {
          router.goNamed(RouteNames.orders);
        }

      case 'booking_update':
      case 'booking_assigned':
        final bookingId = data['booking_id'] as String?;
        if (bookingId != null) {
          router.goNamed(
            RouteNames.bookingDetail,
            pathParameters: {'id': bookingId},
          );
        } else {
          router.goNamed(RouteNames.bookings);
        }

      default:
        debugPrint('NotificationHandler: Unknown type "$type"');
    }
  }
}
