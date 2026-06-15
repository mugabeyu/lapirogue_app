import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage guest session and authentication state
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static final _supabase = Supabase.instance.client;

  /// Get current user session
  static Session? get currentSession => _supabase.auth.currentSession;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current guest data
  static Future<Map<String, dynamic>?> getCurrentGuest() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('auth_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting current guest: $e');
      return null;
    }
  }

  /// Get current guest ID
  static Future<String?> getCurrentGuestId() async {
    final guest = await getCurrentGuest();
    return guest?['id']?.toString();
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;
}
