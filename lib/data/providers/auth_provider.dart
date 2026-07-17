import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/guest.dart';
import '../../core/services/session_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/error_messages.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final Guest? guest;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.guest,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get needsOnboarding => isAuthenticated && guest == null;

  bool get isEmailConfirmed {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  AuthState copyWith({
    AuthStatus? status,
    Guest? guest,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      guest: guest ?? this.guest,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _loadGuest();
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await _loadGuest();
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    });
  }

  Future<void> _loadGuest() async {
    state = state.copyWith(isLoading: true);
    try {
      final guestData = await SessionService.getCurrentGuest();
      if (guestData != null) {
        final guest = Guest.fromJson(guestData);
        state = AuthState(
          status: AuthStatus.authenticated,
          guest: guest,
          isLoading: false,
        );
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          guest: null,
          error: null,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'We couldn\'t load your profile. Please try again.');
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lockout = await Supabase.instance.client.rpc(
        'check_login_lockout',
        params: {'p_email': email},
      );
      if (lockout is Map && lockout['locked'] == true) {
        state = state.copyWith(isLoading: false, error: _lockoutMessage(lockout));
        return;
      }
    } catch (_) {
      // If the lockout check itself fails, don't block a legitimate login attempt.
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      try {
        await Supabase.instance.client.rpc(
          'record_login_attempt',
          params: {'p_email': email, 'p_success': true},
        );
      } catch (_) {}

      await _loadGuest();
    } catch (e) {
      Map<String, dynamic>? attemptState;
      try {
        final result = await Supabase.instance.client.rpc(
          'record_login_attempt',
          params: {'p_email': email, 'p_success': false},
        );
        if (result is Map) attemptState = Map<String, dynamic>.from(result);
      } catch (_) {}

      // Progressive delay: wait longer for each additional failed attempt.
      final attempts = (attemptState?['attempts'] as int?) ?? 1;
      await Future.delayed(Duration(seconds: attempts.clamp(1, 5)));

      if (attemptState != null && attemptState['locked'] == true) {
        final lockedUntil = attemptState['lockedUntil'] as String?;
        if (lockedUntil != null) {
          _sendLockoutAlertEmail(email, lockedUntil);
        }
        state = state.copyWith(isLoading: false, error: _lockoutMessage(attemptState));
        return;
      }

      final remaining = attemptState?['remainingAttempts'] as int?;
      final suffix = remaining != null
          ? ' $remaining attempt${remaining == 1 ? '' : 's'} remaining before your account is temporarily locked.'
          : '';
      state = state.copyWith(isLoading: false, error: 'Invalid credentials.$suffix');
    }
  }

  String _lockoutMessage(Map lockout) {
    final seconds = (lockout['remainingSeconds'] as int?) ?? 15 * 60;
    final minutes = (seconds / 60).ceil().clamp(1, 999);
    return 'This account is temporarily locked due to repeated failed login attempts. Please try again in $minutes minute${minutes == 1 ? '' : 's'}.';
  }

  Future<void> _sendLockoutAlertEmail(String email, String lockedUntil) async {
    try {
      final baseUrl = await AuthService().baseUrl;
      await http.post(
        Uri.parse('$baseUrl/api/auth/security-alert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'lockedUntil': lockedUntil}),
      );
    } catch (_) {
      // Best-effort: never let alert-email failure affect the login flow.
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        state = state.copyWith(isLoading: false, error: 'Registration failed');
        return false;
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyAuthError(e),
      );
      return false;
    }
  }

  Future<bool> createGuestRecord({
    required String firstName,
    required String lastName,
    String? phone,
    String? nationality,
    String? passport,
    String? dateOfBirth,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await Supabase.instance.client.rpc(
        'create_guest_profile',
        params: {
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_phone': phone,
          'p_nationality': nationality,
          'p_passport': passport,
          'p_date_of_birth': dateOfBirth,
          'p_gender': gender,
        },
      );
      if (result['success'] == true) {
        await _loadGuest();
        return true;
      }
      state = state.copyWith(isLoading: false, error: result['error']);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create profile: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshGuest() async {
    await _loadGuest();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});
