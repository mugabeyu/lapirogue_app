import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

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
      if (kDebugMode) debugPrint('getMessages error: $e');
      return [];
    }
  }

  Future<bool> sendMessage({
    required String guestId,
    required String content,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
  }) async {
    try {
      final payload = {
        'guest_id': guestId,
        'content': content,
        'sender_type': 'guest',
        'is_read': false,
      } as Map<String, dynamic>;
      if (fileUrl != null) payload['file_url'] = fileUrl;
      if (fileName != null) payload['file_name'] = fileName;
      if (fileType != null) payload['file_type'] = fileType;
      if (fileSize != null) payload['file_size'] = fileSize;

      await _client.from('messages').insert(payload);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('sendMessage error: $e');
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
      if (kDebugMode) debugPrint('getUnreadCount error: $e');
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
      if (kDebugMode) debugPrint('markAsRead error: $e');
      return false;
    }
  }
}