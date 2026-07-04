import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

// Backward-compatible static getters for old theme API
// Will be removed after all screens are migrated to AppColors
class AppTheme {
  AppTheme._();

  // ── Old color aliases (const for backward compat) ──
  static const Color primary = AppColors.darkNavy;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textTertiary = AppColors.textTertiary;
  static const Color background = AppColors.background;
  static const Color accentGreen = AppColors.statusConfirmed;
  static const Color accentOrange = AppColors.goldAccent;
  static const Color accentRed = AppColors.statusCancelled;
  static const Color borderLight = AppColors.lightGray2;
  static const Color cardBackground = AppColors.cardLight;

  // ── Old typography aliases ──
  static TextStyle get sectionHeader => AppTypography.sectionTitle;
  static TextStyle get sectionHeaderSmall => AppTypography.cardTitle;
  static TextStyle get captionSmallBold => AppTypography.captionMedium;
  static TextStyle get pageTitle => AppTypography.heading;
  static TextStyle get bodyLarge => AppTypography.body;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          headlineLarge: AppTypography.heading,
          headlineMedium: AppTypography.sectionTitle,
          titleLarge: AppTypography.cardTitle,
          titleMedium: AppTypography.bodyMedium,
          bodyLarge: AppTypography.body,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
          labelLarge: AppTypography.button,
          labelMedium: AppTypography.captionMedium,
          labelSmall: AppTypography.small,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.darkNavy,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.darkNavyLight,
        secondary: AppColors.goldAccent,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.goldAccentLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.lightGray,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.lightGray2,
        error: AppColors.statusCancelled,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.cardTitle.copyWith(
          color: AppColors.darkNavy,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.darkNavy,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkNavy,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkNavy,
          side: const BorderSide(color: AppColors.lightGray2, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldAccent,
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkNavy, width: 1.5),
        ),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTypography.caption.copyWith(color: AppColors.textTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGray2,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.darkNavy,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          headlineLarge: AppTypography.heading,
          headlineMedium: AppTypography.sectionTitle,
          bodyMedium: AppTypography.body,
          labelLarge: AppTypography.button,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldAccent,
        onPrimary: AppColors.darkNavy,
        primaryContainer: AppColors.goldAccentDark,
        secondary: AppColors.darkNavy,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textOnDark,
        surfaceContainerHighest: AppColors.darkNavyLight,
        error: AppColors.statusCancelled,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
    );
  }
}
