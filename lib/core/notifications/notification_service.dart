import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'notification_handler.dart';

/// Top-level function required by Firebase for background message handling.
/// Must be a top-level or static function (not an instance method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('NotificationService: Background message received – ${message.messageId}');
}

/// Manages push notifications (FCM) and local notification display.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GoRouter? _router;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Call once during app startup (after Firebase.initializeApp).
  ///
  /// [router] is needed so notification taps can navigate the user.
  static Future<void> initialize(GoRouter router) async {
    _router = router;

    // Register background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS / macOS / web).
    await _requestPermission();

    // Obtain and save FCM token to backend.
    await _saveFcmToken();

    // Listen for token refresh.
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _saveFcmToken());

    // Create Android notification channel.
    await _createNotificationChannel();

    // Initialize local notifications plugin.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When user taps notification while app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  static Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'NotificationService: Permission status – ${settings.authorizationStatus}',
    );
  }

  // ---------------------------------------------------------------------------
  // FCM token
  // ---------------------------------------------------------------------------

  static Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      debugPrint('NotificationService: FCM token – $token');

      await ApiClient().post(
        ApiEndpoints.saveFcmToken,
        data: {
          'fcm_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to save FCM token – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Android notification channel
  // ---------------------------------------------------------------------------

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'freshkart_channel', // id
      'FreshKart Notifications', // name
      description: 'Notifications for orders, bookings and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // Foreground message → show local notification
  // ---------------------------------------------------------------------------

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'NotificationService: Foreground message – ${message.notification?.title}',
    );

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'freshkart_channel',
          'FreshKart Notifications',
          channelDescription: 'Notifications for orders, bookings and updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap handlers
  // ---------------------------------------------------------------------------

  /// Called when user taps a notification while app is in background or
  /// was terminated.
  static void _handleNotificationTap(RemoteMessage message) {
    if (_router == null) return;
    NotificationHandler.handleNotificationTap(
      _router!,
      Map<String, dynamic>.from(message.data),
    );
  }

  /// Called when user taps a local notification shown in the foreground.
  static void _onLocalNotificationTap(NotificationResponse response) {
    if (_router == null || response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      NotificationHandler.handleNotificationTap(_router!, data);
    } catch (e) {
      debugPrint('NotificationService: Failed to parse notification payload – $e');
    }
  }
}
