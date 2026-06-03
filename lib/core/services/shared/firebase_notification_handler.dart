import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_service.dart';
import '../../../firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FirebaseNotificationHandler {
  static final FirebaseNotificationHandler _instance = FirebaseNotificationHandler._internal();
  factory FirebaseNotificationHandler() => _instance;
  FirebaseNotificationHandler._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _localNotifications.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (details) => _handleNotificationTap(details.payload),
      );

      // Create notification channel (Android)
      const channel = AndroidNotificationChannel(
        'hotelsewa_channel', 'HotelSewa Notifications',
        description: 'Booking updates, deals and more',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Get and save FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
        await _saveFcmToken(token);
      }

      // Token refresh
      _messaging.onTokenRefresh.listen(_saveFcmToken);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // Check initial message (app launched from notification)
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleNotificationOpen(initial);

    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      final authToken = prefs.getString('authToken');
      if (authToken != null) {
        await NotificationService().updateFCMToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hotelsewa_channel', 'HotelSewa Notifications',
          channelDescription: 'Booking updates, deals and more',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('[FCM] Opened: ${message.data}');
    _handleNotificationTap(message.data['route']);
  }

  void _handleNotificationTap(String? route) {
    if (route == null || route.isEmpty) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (route) {
      case 'bookings':
        navigator.pushNamed('/my-trips');
        break;
      case 'wallet':
        navigator.pushNamed('/wallet');
        break;
      case 'notifications':
        navigator.pushNamed('/notifications');
        break;
      default:
        if (route.startsWith('/')) navigator.pushNamed(route);
    }
  }
}
