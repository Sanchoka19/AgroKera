import 'package:flutter/material.dart';

/// Single Source of Truth (SSOT) for colors according to DESIGN_SYSTEM.md.
/// Strict adherence to the 60-30-10 Rule.
abstract final class AppColors {
  // ==========================================
  // 60% MAIN (Dominant Base & Surfaces)
  // ==========================================

  /// Primary screen background (#F8FAFC)
  static const Color bgPrimary = Color(0xFFF8FAFC);

  /// Cards, modals, bottom sheets, checkout surfaces (#FFFFFF)
  static const Color surface = Color(0xFFFFFFFF);

  /// Search bar and text input fill (#F2F3F2)
  static const Color surfaceInput = Color(0xFFF2F3F2);

  /// Borders, outlines and dividers (#E2E2E2)
  static const Color border = Color(0xFFE2E2E2);

  // ==========================================
  // 30% SECOND (Structure, Typography & Soft Tints)
  // ==========================================

  /// Deep charcoal text for headings & titles (#181725)
  static const Color textPrimary = Color(0xFF181725);

  /// Secondary muted text for descriptions, units, location (#7C7C7C)
  static const Color textSecondary = Color(0xFF7C7C7C);

  /// Soft leaf tint for category backgrounds & active filters (#EBF7EF)
  static const Color primaryLight = Color(0xFFEBF7EF);

  /// Verification & Trust Blue badge for farmers (#2D9CDB)
  static const Color info = Color(0xFF2D9CDB);

  // ==========================================
  // 10% ACCENT (Primary Brand Color & CTAs)
  // ==========================================

  /// Primary Brand Green: primary buttons, active tabs, prices (#53B175)
  static const Color primary = Color(0xFF53B175);

  /// Darkened primary for pressed / hover states (#439660)
  static const Color primaryDark = Color(0xFF439660);

  /// Text on primary buttons and high-contrast badges (#FFFFFF)
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Warm harvest accent: alerts, discounts, urgency, cancellations (#F3603F)
  static const Color accentWarm = Color(0xFFF3603F);

  /// Star ratings and amber highlight (#F3A938)
  static const Color rating = Color(0xFFF3A938);

  // ==========================================
  // Semantic Aliases & Utilities
  // ==========================================
  static const Color success = primary;
  static const Color error = accentWarm;
  static const Color warning = rating;
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color transparent = Colors.transparent;
}
