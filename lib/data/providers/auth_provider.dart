import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/guest.dart';
import '../../core/services/session_service.dart';

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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _loadGuest();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid credentials');
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
        error: 'Registration failed: $e',
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
