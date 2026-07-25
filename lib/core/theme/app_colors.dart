import 'package:flutter/material.dart';

/// Colour tokens for the La Pirogue guest app.
///
/// The palette is built from a warm neutral ramp plus a single teal brand
/// accent, so hierarchy comes from *neutral weight* (how dark the text is)
/// rather than from colour. Colour is reserved for the few things that
/// genuinely need to be noticed: the primary action, and status.
///
/// Rules this file exists to enforce:
///  • Text hierarchy is three distinct greys, never three copies of black.
///  • Accent colour marks one action per screen, not every interactive thing.
///  • Status colours are only ever used for status.
class AppColors {
  AppColors._();

  // ── Brand accent ────────────────────────────────────────────────────
  // Teal reads as coastal/resort rather than "default framework blue", and
  // sits far enough from the green/amber/red status hues to stay unambiguous.
  static const Color primary = Color(0xFF0F6E6E);
  static const Color primaryLight = Color(0xFF14918F);
  static const Color primaryDark = Color(0xFF0A4F52);
  static const Color primarySoft = Color(0xFFE6F2F1);

  /// Warm sand, for editorial moments (hero overlays, eco/loyalty surfaces).
  /// Deliberately low-saturation so it supports the accent instead of
  /// competing with it.
  static const Color sand = Color(0xFFC8A26A);
  static const Color sandSoft = Color(0xFFF7F1E6);

  // ── Neutrals ────────────────────────────────────────────────────────
  // Very slightly warm greys — a pure-grey ramp next to the teal accent
  // reads cold and clinical.
  static const Color background = Color(0xFFFBFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F2EF);
  static const Color surfaceSunken = Color(0xFFEDEAE5);
  static const Color white = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE4E0DA);
  static const Color borderStrong = Color(0xFFD2CCC3);

  // ── Text ────────────────────────────────────────────────────────────
  // Three genuinely different weights. These were previously all #111827,
  // which flattened every screen into one undifferentiated block of black.
  static const Color textPrimary = Color(0xFF1A1A18); // headings, values
  static const Color textSecondary = Color(0xFF5C5A55); // body, descriptions
  static const Color textTertiary = Color(0xFF8A8781); // labels, meta, hints
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF7F5F2);

  // ── Status ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1F7A4D);
  static const Color successSoft = Color(0xFFE3F3EA);

  static const Color warning = Color(0xFFB26A05);
  static const Color warningSoft = Color(0xFFFBEEDC);

  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFFAE7E5);

  static const Color info = Color(0xFF1D5B8F);
  static const Color infoSoft = Color(0xFFE4EFF7);

  static const Color neutralStatus = Color(0xFF6B6862);
  static const Color neutralStatusSoft = Color(0xFFEFEDE9);

  // ── Misc accents ────────────────────────────────────────────────────
  static const Color ratingStar = Color(0xFFE0A02C);
  static const Color overlayScrim = Color(0x66000000);

  // ── Legacy aliases ──────────────────────────────────────────────────
  // Kept so the ~50 screens still referencing the old names keep compiling
  // while they migrate; every one of these now resolves into the palette
  // above rather than to the old flat blue.
  static const Color darkNavy = primary;
  static const Color darkNavyLight = primaryLight;
  static const Color darkNavyDark = primaryDark;
  static const Color goldAccent = sand;
  static const Color goldAccentLight = sandSoft;
  static const Color lightGray = surfaceMuted;
  static const Color lightGray2 = border;
  static const Color surfaceLight = surface;
  static const Color cardLight = surface;

  static const Color statusConfirmed = success;
  static const Color statusConfirmedBg = successSoft;
  static const Color statusPending = warning;
  static const Color statusPendingBg = warningSoft;
  static const Color statusCancelled = danger;
  static const Color statusCancelledBg = dangerSoft;
  static const Color statusInfo = info;
  static const Color statusInfoBg = infoSoft;
  static const Color statusNeutral = neutralStatus;
  static const Color statusNeutralBg = neutralStatusSoft;

  static const Color ecoGreen = success;
  static const Color ecoGreenLight = successSoft;
}
