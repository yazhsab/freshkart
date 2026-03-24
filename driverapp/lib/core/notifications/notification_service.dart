import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();

  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel
  static const String _channelId = 'delivery_channel';
  static const String _channelName = 'Delivery Alerts';
  static const String _channelDescription =
      'Notifications for new delivery orders and updates';

  // Notification types
  static const String typeNewDeliveryAvailable = 'new_delivery_available';
  static const String typeOrderAssigned = 'order_assigned';
  static const String typeDeliveryReminder = 'delivery_reminder';
  static const String typePayoutProcessed = 'payout_processed';

  // Callback for when a notification tap opens a specific route
  void Function(String? type, Map<String, dynamic>? data)? onNotificationTap;

  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('NotificationService: Permission denied');
      return;
    }

    // Android notification channel
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

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // When app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check if app was opened from a terminated state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }

    // Register FCM token
    await _registerToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _sendTokenToServer(token);
    });
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to get FCM token: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.registerFcmToken,
        data: {'fcm_token': token},
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to register FCM token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    showNotification(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationData(data);
      } catch (_) {}
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    onNotificationTap?.call(type, data);
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final type = data['type'] as String?;

    final title = notification?.title ?? _titleForType(type);
    final body = notification?.body ?? '';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: _importanceForType(type),
      priority: Priority.high,
      playSound: true,
      enableVibration: _shouldVibrate(type),
      showWhen: true,
      category: AndroidNotificationCategory.message,
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
      payload: jsonEncode(data),
    );
  }

  String _titleForType(String? type) {
    switch (type) {
      case typeNewDeliveryAvailable:
        return 'New Delivery Available!';
      case typeOrderAssigned:
        return 'Order Assigned';
      case typeDeliveryReminder:
        return 'Delivery Reminder';
      case typePayoutProcessed:
        return 'Payout Processed';
      default:
        return 'FreshKart Delivery';
    }
  }

  Importance _importanceForType(String? type) {
    switch (type) {
      case typeNewDeliveryAvailable:
        return Importance.max;
      case typeOrderAssigned:
        return Importance.high;
      case typeDeliveryReminder:
        return Importance.high;
      case typePayoutProcessed:
        return Importance.defaultImportance;
      default:
        return Importance.defaultImportance;
    }
  }

  bool _shouldVibrate(String? type) {
    switch (type) {
      case typeNewDeliveryAvailable:
        return true;
      case typeOrderAssigned:
        return true;
      default:
        return false;
    }
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
