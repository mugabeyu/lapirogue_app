import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'guest_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _notificationSubscription;
  bool _initialized = false;

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

    _subscribeToRealtimeNotifications();
  }

  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) debugPrint('Notification tapped: ${response.payload}');
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
