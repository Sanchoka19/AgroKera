import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Single Source of Truth (SSOT) for typography according to DESIGN_SYSTEM.md.
/// Primary font: Inter with Noto Sans Georgian fallback.
/// Cached as static final instances for maximum rendering performance without runtime allocations.
abstract final class AppTypography {
  static const List<String> fontFallbacks = <String>[
    'Noto Sans Georgian',
    'Inter',
    'sans-serif',
  ];

  /// Display / Screen Title: 24px, FontWeight.w700
  static final TextStyle h1 = GoogleFonts.notoSansGeorgian(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  ).copyWith(fontFamilyFallback: fontFallbacks);

  /// Section Header: 18px, FontWeight.w700
  static final TextStyle h2 = GoogleFonts.notoSansGeorgian(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.25,
  ).copyWith(fontFamilyFallback: fontFallbacks);

  /// Card Title / Product Name: 16px, FontWeight.w600
  static final TextStyle titleMedium = GoogleFonts.notoSansGeorgian(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  ).copyWith(fontFamilyFallback: fontFallbacks);

  /// Body / Description: 14px, FontWeight.w400
  static final TextStyle bodyMedium = GoogleFonts.notoSansGeorgian(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.35,
  ).copyWith(fontFamilyFallback: fontFallbacks);

  /// Caption / Unit / Badge: 12px, FontWeight.w500
  static final TextStyle caption = GoogleFonts.notoSansGeorgian(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
  ).copyWith(fontFamilyFallback: fontFallbacks);

  /// Primary Button label: 15.5px, FontWeight.w600, with dedicated Georgian descender clearance
  static final TextStyle button = GoogleFonts.notoSansGeorgian(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.25,
  ).copyWith(fontFamilyFallback: fontFallbacks);

  /// Material 3 TextTheme mapped with the Design System tokens
  static final TextTheme textTheme = TextTheme(
    headlineLarge: h1,
    headlineMedium: h2,
    titleLarge: h2,
    titleMedium: titleMedium,
    titleSmall: titleMedium.copyWith(fontSize: 14),
    bodyLarge: bodyMedium.copyWith(fontSize: 16),
    bodyMedium: bodyMedium,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: caption.copyWith(fontWeight: FontWeight.w600),
    labelSmall: caption.copyWith(fontSize: 10),
  );
}
