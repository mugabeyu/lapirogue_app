import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest.dart';

class GuestService {
  static final GuestService _instance = GuestService._internal();
  factory GuestService() => _instance;
  GuestService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<Guest?> getCurrentGuest() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final byAuthId = await _client
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (byAuthId != null) return Guest.fromJson(byAuthId);

      if (user.email == null) return null;

      final byEmail = await _client
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('email', user.email!)
          .maybeSingle();

      if (byEmail == null) return null;

      try {
        await _client
            .from('guests')
            .update({'auth_id': user.id, 'auth_user_id': user.id})
            .eq('id', byEmail['id']);
      } catch (updateError) {
        if (kDebugMode) debugPrint('Auth link update error: $updateError');
      }

      return Guest.fromJson(byEmail);
    } catch (e) {
      if (kDebugMode) debugPrint('getCurrentGuest error: $e');
      return null;
    }
  }

  Future<String?> getCurrentGuestId() async {
    final guest = await getCurrentGuest();
    return guest?.id;
  }

  Future<Guest?> getGuestById(String guestId) async {
    try {
      final response = await _client
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('id', guestId)
          .maybeSingle();
      return response != null ? Guest.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfileImagePath(String guestId, String imageUrl) async {
    try {
      await _client
          .from('guests')
          .update({'image_path': imageUrl})
          .eq('id', guestId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGuest(String guestId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('guests')
          .update(updates)
          .eq('id', guestId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getUnreadMessagesCount(String guestId) async {
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

  Future<int> getUnreadNotificationsCount(String guestId) async {
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
}