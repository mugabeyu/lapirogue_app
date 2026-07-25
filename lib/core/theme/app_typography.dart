import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale for the guest app.
///
/// The previous scale ran 11 → 28 with most of the app crammed into 13/15/17,
/// so nothing looked more important than anything else. This one uses a
/// wider range and bigger jumps between adjacent steps, which is what makes
/// a screen scannable.
///
/// Two conventions borrowed from apps that read well on a phone (TikTok,
/// Airbnb, Revolut):
///  • Large text gets tighter letter spacing and shorter line height; small
///    text gets looser tracking. Uniform tracking is what makes type look
///    amateurish at display sizes.
///  • Numbers that sit in columns or change in place use tabular figures so
///    they stop shifting sideways as the value updates.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  /// Lining, fixed-width digits — for prices, counters, dates and OTP boxes.
  static const List<FontFeature> _tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // ── Display: one per screen at most, for the page's subject ──────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.16,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  // ── Headings ────────────────────────────────────────────────────────
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  // ── Body ────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// All-caps eyebrow above a section. The wide tracking is what stops small
  /// caps from reading as a cramped smudge.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.9,
    color: AppColors.textTertiary,
  );

  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textTertiary,
  );

  // ── Interactive ─────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // ── Numeric ─────────────────────────────────────────────────────────
  static const TextStyle price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    fontFeatures: _tabularFigures,
  );

  /// Single characters in the verification-code boxes.
  static const TextStyle code = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
    fontFeatures: _tabularFigures,
  );
}
