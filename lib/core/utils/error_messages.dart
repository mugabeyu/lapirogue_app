import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts Supabase/Postgres exceptions into short, friendly messages
/// that are safe to show to a guest. Never surfaces raw backend text.
String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();

    if (msg.contains('security purposes') || msg.contains('seconds')) {
      return 'Please wait a moment before trying again.';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('invalid') && (msg.contains('otp') || msg.contains('token'))) {
      return 'Invalid or expired code. Please request a new one.';
    }
    if (msg.contains('invalid') || msg.contains('expired')) {
      return 'Invalid or expired code. Please request a new one.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return 'Please choose a stronger password (at least 8 characters).';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Connection problem. Please check your internet and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}
