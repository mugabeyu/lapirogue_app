import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'guest_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _notificationSubscription;
  bool _initialized = false;
  bool _fcmAttempted = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Local notifications init error: $e');
    }

    _initFirebaseMessaging();
    _subscribeToRealtimeNotifications();
  }

  Future<void> _initFirebaseMessaging() async {
    if (_fcmAttempted) return;
    _fcmAttempted = true;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _storeFcmToken(token);
        }

        FirebaseMessaging.instance.onTokenRefresh.listen(_storeFcmToken);
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationData(initialMessage.data);
      }

      if (kDebugMode) debugPrint('Firebase Messaging initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase Messaging init skipped (non-fatal): $e');
    }
  }

  Future<void> _storeFcmToken(String token) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('guests').update({'fcm_token': token}).eq('auth_id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Store FCM token error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] as String? ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] as String? ?? '';
    final payload = message.data['id'] as String? ?? '';

    _showLocalNotification(title, body, payload);
  }

  void _handleNotificationOpenedApp(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final type = data['type'] as String?;
    if (kDebugMode) debugPrint('Notification data: id=$id type=$type');
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      if (kDebugMode) debugPrint('Notification tapped: $payload');
    }
  }

  void _subscribeToRealtimeNotifications() {
    final guest = _client.auth.currentUser;
    if (guest == null) return;

    _notificationSubscription?.cancel();

    _notificationSubscription = _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .listen((notifications) async {
      final currentGuest = await GuestService().getCurrentGuest();
      if (currentGuest == null) return;

      for (final notif in notifications) {
        final guestId = notif['guest_id'] as String?;
        if (guestId == null || guestId != currentGuest.id) continue;

        final title = notif['title'] as String? ?? 'Notification';
        final message = notif['message'] as String? ?? '';
        final id = notif['id'] as String? ?? '';

        _showLocalNotification(title, message, id);
      }
    });
  }

  Future<void> _showLocalNotification(String title, String body, String payload) async {
    const androidDetails = AndroidNotificationDetails(
      'hotel_notifications',
      'Hotel Notifications',
      channelDescription: 'Notifications from La Pirogue Hotel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = payload.hashCode % 10000;
    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Show notification error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final android = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
      }
      try {
        final ios = _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) {
          await ios.requestPermissions(alert: true, badge: true, sound: true);
        }
      } catch (_) {}
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _notificationSubscription?.cancel();
  }
}
