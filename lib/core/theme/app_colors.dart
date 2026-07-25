import 'package:flutter/material.dart';

/// Design tokens matching the La Pirogue guest-app reference design
/// (clean white surfaces, blue-600 primary accent, soft status pills).
class AppColors {
  AppColors._();

  // ── Primary accent (used for CTAs, active nav, links, focus rings) ──
  // Kept the old field names (darkNavy / goldAccent) for backward
  // compatibility with the ~50 screens that already reference them —
  // only the underlying values changed.
  static const Color darkNavy = Color(0xFF2563EB); // primary blue-600
  static const Color darkNavyLight = Color(0xFF3B82F6); // blue-500
  static const Color darkNavyDark = Color(0xFF1D4ED8); // blue-700

  static const Color goldAccent = Color(0xFF2563EB); // same accent as primary
  static const Color goldAccentLight = Color(0xFF60A5FA); // blue-400

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF); // blue-50 tint bg

  static const Color background = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF3F4F6); // gray-100
  static const Color lightGray2 = Color(0xFFE5E7EB); // gray-200 (borders)

  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF111827); // black (was gray-500)
  static const Color textTertiary = Color(0xFF111827); // black (was gray-400)
  static const Color textOnPrimary = Colors.white;

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Colors.white;

  // ── Status colors + soft background tints for pill badges ──
  static const Color statusConfirmed = Color(0xFF059669); // emerald-600
  static const Color statusConfirmedBg = Color(0xFFD1FAE5);

  static const Color statusPending = Color(0xFFD97706); // amber-600
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  static const Color statusCancelled = Color(0xFFDC2626); // red-600
  static const Color statusCancelledBg = Color(0xFFFEE2E2);

  static const Color statusInfo = Color(0xFF2563EB); // blue-600
  static const Color statusInfoBg = Color(0xFFDBEAFE);

  static const Color statusNeutral = Color(0xFF6B7280); // gray-500
  static const Color statusNeutralBg = Color(0xFFF3F4F6);

  // ── Misc accents ──
  static const Color ratingStar = Color(0xFFF59E0B); // amber-500
  static const Color ecoGreen = Color(0xFF059669);
  static const Color ecoGreenLight = Color(0xFFECFDF5);
}
