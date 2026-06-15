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

  /// Get current guest data
  static Future<Map<String, dynamic>?> getCurrentGuest() async {
    final user = currentUser;
    if (user == null) return null;
    return await getGuestByAuthId(user.id);
  }

  /// Get current guest ID
  static Future<String?> getCurrentGuestId() async {
    final guest = await getCurrentGuest();
    return guest?['id']?.toString();
  }
}
