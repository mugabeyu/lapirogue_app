import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<AppNotification>> getNotifications(String guestId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .or('guest_id.eq.$guestId,guest_id.is.null')
          .order('created_at', ascending: false);
      return response.map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading notifications: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error marking notification read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String guestId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('guest_id', guestId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error marking all notifications read: $e');
      return false;
    }
  }
}