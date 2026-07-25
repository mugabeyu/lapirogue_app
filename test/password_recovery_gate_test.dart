import 'package:flutter_test/flutter_test.dart';

import 'package:lapirogue_hotel/data/providers/auth_provider.dart';

/// Verifying a password-reset code makes Supabase issue a real session,
/// because `updateUser(password:)` cannot work without one. The app must not
/// read that session as a completed sign-in — otherwise possession of the
/// emailed code alone opens the whole app, before any new password exists.
///
/// These tests pin the state machine that keeps the two apart. The router
/// reads exactly these getters to decide where the guest may go.

void main() {
  group('AuthState during password recovery', () {
    test('a recovery session does not count as signed in', () {
      const state = AuthState(status: AuthStatus.passwordRecovery);

      expect(state.isAuthenticated, isFalse,
          reason: 'a verified code alone must not grant access to the app');
      expect(state.isRecoveringPassword, isTrue);
    });

    test('recovery never triggers the onboarding redirect', () {
      // `needsOnboarding` is what sent guests to /onboarding — and from there
      // into the app — the moment the code was accepted.
      const state = AuthState(status: AuthStatus.passwordRecovery);

      expect(state.needsOnboarding, isFalse);
    });

    test('a real sign-in is still reported as authenticated', () {
      const state = AuthState(status: AuthStatus.authenticated);

      expect(state.isAuthenticated, isTrue);
      expect(state.isRecoveringPassword, isFalse);
    });

    test('signed out is neither', () {
      const state = AuthState(status: AuthStatus.unauthenticated);

      expect(state.isAuthenticated, isFalse);
      expect(state.isRecoveringPassword, isFalse);
    });

    test('copyWith preserves the recovery hold', () {
      const state = AuthState(status: AuthStatus.passwordRecovery);
      final busy = state.copyWith(isLoading: true);

      expect(busy.isRecoveringPassword, isTrue,
          reason: 'a loading toggle must not silently release the hold');
      expect(busy.isAuthenticated, isFalse);
    });
  });
}
