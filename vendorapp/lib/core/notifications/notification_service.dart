import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';
import 'package:freshkart_vendor/core/router/app_router.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';

/// Top-level handler for background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class VendorNotificationService {
  VendorNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static const String _channelId = 'freshkart_vendor_channel';
  static const String _channelName = 'FreshKart Vendor Notifications';
  static const String _channelDescription =
      'Order alerts and important updates for FreshKart vendors';

  /// Initialize the full notification pipeline
  static Future<void> initialize() async {
    // 1. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notification permission denied');
      return;
    }

    // 2. Get and save FCM token
    await _getAndSaveToken();

    // 3. Create high-priority Android notification channel
    await _createNotificationChannel();

    // 4. Initialize local notifications
    await _initLocalNotifications();

    // 5. Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Handle notification taps (background & terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. Handle terminated-state tap (app opened via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 9. Token refresh listener
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  static Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
        await _saveTokenToServer(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  static Future<void> _onTokenRefresh(String token) async {
    debugPrint('[FCM] Token refreshed');
    await _saveTokenToServer(token);
  }

  static Future<void> _saveTokenToServer(String token) async {
    try {
      await ApiClient.instance.post(
        VendorApiEndpoints.fcmToken,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app': 'vendor',
        },
      );
      await LocalStorage.instance.setString('fcm_token', token);
    } catch (e) {
      debugPrint('[FCM] Failed to save token to server: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Channel setup
  // ---------------------------------------------------------------------------

  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  // ---------------------------------------------------------------------------
  // Foreground message handling
  // ---------------------------------------------------------------------------

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.data}');

    final type = message.data['type'] as String? ?? '';
    final notification = message.notification;

    if (type == 'new_order') {
      // Play urgent sound
      await _playNewOrderSound();

      // Vibrate with urgent pattern
      await _vibrateUrgent();

      // Show heads-up notification
      await _showLocalNotification(
        title: notification?.title ?? 'New Order!',
        body: notification?.body ?? 'You have a new order waiting',
        payload: jsonEncode(message.data),
        isUrgent: true,
      );
    } else {
      // Standard notification for other types
      await _showLocalNotification(
        title: notification?.title ?? 'FreshKart Vendor',
        body: notification?.body ?? '',
        payload: jsonEncode(message.data),
        isUrgent: false,
      );
    }
  }

  static Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource('audio/new_order.mp3'));
    } catch (e) {
      debugPrint('[FCM] Error playing sound: $e');
    }
  }

  static Future<void> _vibrateUrgent() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('[FCM] Vibration error: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isUrgent = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      category: isUrgent ? AndroidNotificationCategory.alarm : null,
      fullScreenIntent: isUrgent,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap handling
  // ---------------------------------------------------------------------------

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    _navigateFromPayload(data);
  }

  static void _onLocalNotificationTap(
    NotificationResponse notificationResponse,
  ) {
    final payload = notificationResponse.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (e) {
      debugPrint('[FCM] Error parsing notification payload: $e');
    }
  }

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final router = AppRouter.router;

    switch (type) {
      case 'new_order':
        router.go('/orders');
        break;
      case 'order_status_update':
        final orderId = data['order_id'] as String? ?? '';
        if (orderId.isNotEmpty) {
          router.go('/orders/$orderId');
        } else {
          router.go('/orders');
        }
        break;
      case 'low_stock_alert':
        router.go('/inventory/low-stock');
        break;
      case 'payout_processed':
        router.go('/earnings');
        break;
      default:
        router.go('/dashboard');
    }
  }
}
