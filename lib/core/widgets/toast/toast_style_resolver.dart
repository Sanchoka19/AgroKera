import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import 'toast_model.dart';

/// Style specifications for a resolved toast type.
class ToastStyle {
  final Color dropletColor;
  final Color badgeBgColor;
  final Color iconColor;
  final IconData defaultIcon;
  final Color textColor;
  final Color borderColor;
  final Color actionBgColor;

  const ToastStyle({
    required this.dropletColor,
    required this.badgeBgColor,
    required this.iconColor,
    required this.defaultIcon,
    this.textColor = const Color(0xFF0F172A),
    this.borderColor = const Color(0xFFE2E8F0),
    this.actionBgColor = AppColors.primary,
  });
}

/// Pure styling resolver mapping ToastType to ToastStyle without Flutter rendering widgets.
abstract final class ToastStyleResolver {
  static ToastStyle resolve(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const ToastStyle(
          dropletColor: AppColors.primary,
          badgeBgColor: Color(0xFFEBF7EF),
          iconColor: AppColors.primary,
          defaultIcon: LucideIcons.check,
        );

      case ToastType.error:
        return const ToastStyle(
          dropletColor: Color(0xFFEF4444),
          badgeBgColor: Color(0xFFFEE2E2),
          iconColor: Color(0xFFDC2626),
          defaultIcon: LucideIcons.circleX,
        );

      case ToastType.warning:
        return const ToastStyle(
          dropletColor: Color(0xFFF59E0B),
          badgeBgColor: Color(0xFFFEF3C7),
          iconColor: Color(0xFFD97706),
          defaultIcon: LucideIcons.circleAlert,
        );

      case ToastType.info:
        return const ToastStyle(
          dropletColor: Color(0xFF0EA5E9),
          badgeBgColor: Color(0xFFE0F2FE),
          iconColor: Color(0xFF0284C7),
          defaultIcon: LucideIcons.info,
        );
    }
  }
}
