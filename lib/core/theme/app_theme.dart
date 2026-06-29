import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_typography.dart';

/// La Pirogue Hotel App Theme
/// Professional luxury hotel color palette
class AppTheme {
  AppTheme._();

  // Primary Colors - Resort Navy Blue
  static const Color primary = Color(0xFF002B5C);
  static const Color primaryLight = Color(0xFF1A4A7A);
  static const Color primaryDark = Color(0xFF001A38);

  // Secondary Colors - Warm Gold/Sand
  static const Color secondary = Color(0xFFD4A574);
  static const Color secondaryLight = Color(0xFFE8C9A0);
  static const Color secondaryDark = Color(0xFFB0855A);

  // Accent Colors
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentOrange = Color(0xFFF4A340);
  static const Color accentPurple = Color(0xFF9C27B0);

  // Background Colors
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);

  // Status Colors
  static const Color statusConfirmed = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusCancelled = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: AppTypography.pageTitleLarge,
          displayMedium: AppTypography.pageTitle,
          displaySmall: AppTypography.pageTitleSmall,
          headlineLarge: AppTypography.sectionHeaderLarge,
          headlineMedium: AppTypography.sectionHeader,
          headlineSmall: AppTypography.sectionHeaderSmall,
          titleLarge: AppTypography.sectionHeaderSmall,
          titleMedium: AppTypography.bodyBold,
          titleSmall: AppTypography.buttonSmall,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
          labelLarge: AppTypography.button,
          labelMedium: AppTypography.label,
          labelSmall: AppTypography.chip,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: textOnPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: textOnPrimary,
        secondary: secondary,
        onSecondary: textPrimary,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: background,
        onSurfaceVariant: textSecondary,
        outline: borderMedium,
        error: accentRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        titleTextStyle: AppTypography.sectionHeaderSmall.copyWith(
          color: textOnPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTypography.buttonSmall,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        labelStyle: AppTypography.label.copyWith(
          color: textSecondary,
        ),
        hintStyle: AppTypography.hint.copyWith(
          color: textTertiary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primary.withValues(alpha: 0.1),
        labelStyle: AppTypography.chip.copyWith(
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 40,
        titleTextStyle: AppTypography.bodyBold.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: AppTypography.caption.copyWith(
          color: textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: textPrimary,
        contentTextStyle: AppTypography.captionBold.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
