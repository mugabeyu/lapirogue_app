import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // Page Titles / Large Headings: 28px – 34px
  static const TextStyle pageTitleLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle pageTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle pageTitleSmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  // Section Headers (H2/H3): 20px – 24px
  static const TextStyle sectionHeaderLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle sectionHeaderSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Body / Paragraph Text: 16px – 18px
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Buttons / Primary Actions: 16px – 18px (bolder weight)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Secondary Text / Captions: 12px – 14px
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle captionBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle captionSmallBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Label / Input
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
