import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/guest.dart';
import '../../core/services/session_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/error_messages.dart';

enum AuthStatus {
  unauthenticated,
  authenticated,

  /// A recovery code has been verified but the new password has not been set
  /// yet.
  ///
  /// Supabase issues a real session the moment a recovery OTP is verified —
  /// `updateUser(password:)` cannot work without one. Reporting that session
  /// as `authenticated` would sign the guest straight into the app on the
  /// strength of an emailed code alone, before they have chosen a password.
  /// This status keeps the session usable for the password update while the
  /// rest of the app still treats them as signed out.
  passwordRecovery,
}

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

  bool get isRecoveringPassword => status == AuthStatus.passwordRecovery;

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

  /// Set while the guest is part-way through a password reset, so the session
  /// that `verifyOTP` creates is not mistaken for a completed sign-in.
  bool _inPasswordRecovery = false;

  /// Mirrors [_inPasswordRecovery] to disk. Supabase persists the recovery
  /// session, and a session created by a recovery code is indistinguishable
  /// from a normal one after a restart — so if the app is killed between
  /// verifying the code and saving the password, the next launch would sign
  /// the guest in for free. This marker lets that launch recognise the
  /// half-finished reset and throw the session away.
  static const _recoveryFlagKey = 'password_recovery_in_progress';

  Future<void> _setPersistedRecoveryFlag(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_recoveryFlagKey, true);
      } else {
        await prefs.remove(_recoveryFlagKey);
      }
    } catch (_) {
      // Storage is best-effort; the in-memory flag still guards this session.
    }
  }

  Future<bool> _readPersistedRecoveryFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_recoveryFlagKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    try {
      final session = Supabase.instance.client.auth.currentSession;

      // A session left over from an abandoned password reset must not become
      // a login just because the app restarted.
      if (session != null && await _readPersistedRecoveryFlag()) {
        await _setPersistedRecoveryFlag(false);
        await Supabase.instance.client.auth.signOut();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        _listenForAuthChanges();
        return;
      }

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

    _listenForAuthChanges();
  }

  void _listenForAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      // A recovery deep link produces this event directly; the OTP path sets
      // the flag itself before verifying, since that emits a plain sign-in.
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _inPasswordRecovery = true;
        await _setPersistedRecoveryFlag(true);
      }

      if (data.session != null) {
        if (_inPasswordRecovery) {
          state = const AuthState(
            status: AuthStatus.passwordRecovery,
            isLoading: false,
          );
          return;
        }
        await _loadGuest();
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    });
  }

  /// Call before verifying a recovery code, so the session it creates does not
  /// count as a sign-in.
  Future<void> beginPasswordRecovery() async {
    _inPasswordRecovery = true;
    state = const AuthState(status: AuthStatus.passwordRecovery);
    await _setPersistedRecoveryFlag(true);
  }

  /// Clears the recovery hold once the new password has been saved.
  Future<void> endPasswordRecovery() async {
    _inPasswordRecovery = false;
    await _setPersistedRecoveryFlag(false);
  }

  /// Drops the half-finished recovery session so an abandoned reset cannot
  /// leave the app signed in.
  Future<void> cancelPasswordRecovery() async {
    if (!_inPasswordRecovery) return;
    _inPasswordRecovery = false;
    await _setPersistedRecoveryFlag(false);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Already signed out, or offline — the local state below is what the
      // rest of the app reads.
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
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
    _inPasswordRecovery = false;
    await _setPersistedRecoveryFlag(false);
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
