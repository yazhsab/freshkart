import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/storage/local_storage.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static GoRouter? _router;

  static const _channel = AndroidNotificationChannel(
    'worker_channel',
    'Worker Notifications',
    description: 'Notifications for FreshKart workers',
    importance: Importance.high,
  );

  static const _bookingChannel = AndroidNotificationChannel(
    'booking_alerts',
    'Booking Alerts',
    description: 'New booking assignment alerts',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize(GoRouter router) async {
    _router = router;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    await android?.createNotificationChannel(_bookingChannel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      LocalStorage.fcmToken = token;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      LocalStorage.fcmToken = token;
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final isBookingAlert = message.data['type'] == 'new_booking';
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isBookingAlert ? _bookingChannel.id : _channel.id,
          isBookingAlert ? _bookingChannel.name : _channel.name,
          channelDescription: isBookingAlert
              ? _bookingChannel.description
              : _channel.description,
          importance: isBookingAlert ? Importance.max : Importance.high,
          priority: isBookingAlert ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateFromPayload(message.data);
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (_) {}
  }

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final bookingId = data['booking_id'] as String?;

    if (_router == null) return;

    switch (type) {
      case 'new_booking':
      case 'booking_update':
        if (bookingId != null) {
          _router!.push('/booking/$bookingId');
        }
        break;
      case 'bgv_update':
        _router!.go('/profile');
        break;
      case 'payout':
        _router!.push('/payout-history');
        break;
      default:
        break;
    }
  }
}
