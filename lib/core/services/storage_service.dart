import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<String?> uploadGuestPhoto(String guestId, File file) async {
    try {
      final fileName = 'guest_${guestId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('guest-photos')
          .upload(fileName, file);

      final imageUrl = _client.storage
          .from('guest-photos')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadFoodOrderImage(String orderId, File file) async {
    try {
      final fileName = 'order_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('chat_uploads')
          .upload(fileName, file);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}