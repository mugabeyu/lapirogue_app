import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service for database operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Get current session
  static Session? get currentSession => auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Reset password
  static Future<void> resetPasswordForEmail(String email) async {
    await auth.resetPasswordForEmail(email);
  }

  /// Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    return await auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;

  /// Get guest data by auth_id
  static Future<Map<String, dynamic>?> getGuestByAuthId(String authId) async {
    try {
      final response = await client
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('auth_id', authId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get guest data by email
  static Future<Map<String, dynamic>?> getGuestByEmail(String email) async {
    try {
      final response = await client
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('email', email)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get guest data by ID
  static Future<Map<String, dynamic>?> getGuestById(String guestId) async {
    try {
      final response = await client
          .from('guests')
          .select('*, reservations(*, rooms(*))')
          .eq('id', guestId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get current guest data (with email fallback)
  static Future<Map<String, dynamic>?> getCurrentGuest() async {
    final user = currentUser;
    if (user == null) return null;

    var guest = await getGuestByAuthId(user.id);
    if (guest != null) return guest;

    if (user.email == null) return null;

    guest = await getGuestByEmail(user.email!);
    if (guest == null) return null;

    try {
      await client
          .from('guests')
          .update({'auth_id': user.id, 'auth_user_id': user.id})
          .eq('id', guest['id']);
    } catch (_) {}

    return guest;
  }

  /// Get current guest ID
  static Future<String?> getCurrentGuestId() async {
    final guest = await getCurrentGuest();
    return guest?['id']?.toString();
  }

  /// Sign in anonymously with Supabase Auth
  static Future<AuthResponse> signInAnonymously() async {
    return await auth.signInAnonymously();
  }

  /// Look up a guest by reservation reference + last name
  /// Calls SECURITY DEFINER RPC function that bypasses RLS
  static Future<Map<String, dynamic>?> lookupGuestByBooking({
    required String reservationId,
    required String lastName,
  }) async {
    try {
      final response = await client.rpc(
        'lookup_guest_by_booking',
        params: {
          'p_reservation_id': reservationId,
          'p_last_name': lastName,
        },
      );
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Booking lookup error: $e');
      return null;
    }
  }

  /// Link anonymous auth user to a guest record
  /// Calls SECURITY DEFINER RPC function that bypasses RLS
  static Future<bool> linkGuestAuth({
    required String guestId,
    required String authId,
  }) async {
    try {
      final response = await client.rpc(
        'link_guest_auth',
        params: {
          'p_guest_id': guestId,
          'p_auth_id': authId,
        },
      );
      return response == true;
    } catch (e) {
      debugPrint('Link guest auth error: $e');
      return false;
    }
  }
}
