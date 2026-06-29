import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<String?> uploadGuestPhoto(String guestId, Uint8List bytes) async {
    try {
      final fileName = 'guest_${guestId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('guest-photos')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      return _client.storage
          .from('guest-photos')
          .getPublicUrl(fileName);
    } catch (e) {
      if (kDebugMode) debugPrint('uploadGuestPhoto error: $e');
      return null;
    }
  }

  Future<bool> uploadFoodOrderImage(String orderId, Uint8List bytes) async {
    try {
      final fileName = 'order_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('chat_uploads')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('uploadFoodOrderImage error: $e');
      return false;
    }
  }

  Future<Map<String, String>?> uploadChatFile({
    required String guestId,
    required String filePath,
    required String fileName,
    Uint8List? bytes,
  }) async {
    try {
      Uint8List fileBytes;
      if (bytes != null) {
        fileBytes = bytes;
      } else {
        final file = File(filePath);
        fileBytes = await file.readAsBytes();
      }

      final ext = fileName.split('.').last.toLowerCase();
      final storagePath = 'chat_${guestId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      String? contentType;
      if (['jpg', 'jpeg'].contains(ext)) {
        contentType = 'image/jpeg';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'gif') {
        contentType = 'image/gif';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'doc') {
        contentType = 'application/msword';
      } else if (ext == 'docx') {
        contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (ext == 'txt') {
        contentType = 'text/plain';
      } else if (ext == 'zip') {
        contentType = 'application/zip';
      } else {
        contentType = 'application/octet-stream';
      }

      await _client.storage
          .from('chat_uploads')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final publicUrl = _client.storage
          .from('chat_uploads')
          .getPublicUrl(storagePath);

      return {'url': publicUrl, 'name': fileName, 'type': contentType};
    } catch (e) {
      if (kDebugMode) debugPrint('uploadChatFile error: $e');
      return null;
    }
  }
}