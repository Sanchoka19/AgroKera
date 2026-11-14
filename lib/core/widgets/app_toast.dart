import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

/// Global Modern Toast Notification for AgroKera.
/// Features a floating pill design, ambient shadows, semantic icons,
/// and optional quick action buttons (e.g. "კალათა ➔").
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    HapticFeedback.lightImpact();

    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (type) {
      case ToastType.success:
        icon = LucideIcons.check;
        iconColor = const Color(0xFF10B981);
        iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.18);
        break;
      case ToastType.error:
        icon = LucideIcons.x;
        iconColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.18);
        break;
      case ToastType.warning:
        icon = LucideIcons.triangleAlert;
        iconColor = const Color(0xFFF59E0B);
        iconBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        break;
      case ToastType.info:
        icon = LucideIcons.info;
        iconColor = const Color(0xFF38BDF8);
        iconBgColor = const Color(0xFF38BDF8).withValues(alpha: 0.18);
        break;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Modern deep slate
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Semantic Icon Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),

              // Message Text
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // Optional Action Button (e.g., "კალათა ➔")
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
