import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/notification.dart';

/// Message Service for guest-to-staff chat
class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<Message>> getMessages(String guestId) async {
    try {
      final response = await _client
          .from('messages')
          .select('*')
          .eq('guest_id', guestId)
          .order('created_at', ascending: true);
      return response.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage({
    required String guestId,
    required String content,
  }) async {
    try {
      await _client.from('messages').insert({
        'guest_id': guestId,
        'content': content,
        'sender_type': 'guest',
        'is_read': false,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getUnreadCount(String guestId) async {
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('guest_id', guestId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Notification Service
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<Notification>> getNotifications(String guestId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('guest_id', guestId)
          .order('created_at', ascending: false);
      return response.map((e) => Notification.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getUnreadCount(String guestId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('guest_id', guestId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      return 0;
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
      return false;
    }
  }
}