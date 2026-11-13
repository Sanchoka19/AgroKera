import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum StatusBadgeVariant { verified, success, warning, danger, neutral }

/// Status and informational badge adhering to DESIGN_SYSTEM.md:
/// - Verified / Trust Blue: #2D9CDB
/// - Success / Green: #53B175 on #EBF7EF
/// - Warning / Pending: #F3A938 on #FEF6E9
/// - Danger / Discount: #F3603F on #FEEFEA
/// - Typography: 12px, w500 (AppTypography.caption)
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
  });

  /// Factory for the Verified Farmer badge (Blue #2D9CDB)
  factory StatusBadge.verified({
    Key? key,
    String label = 'ვერიფიცირებული',
    double iconSize = 13,
  }) {
    return StatusBadge(
      key: key,
      label: label,
      variant: StatusBadgeVariant.verified,
      icon: Icon(LucideIcons.badgeCheck, size: iconSize, color: AppColors.info),
    );
  }

  /// Factory for Success / Ready / Active states
  factory StatusBadge.success({Key? key, required String label, Widget? icon}) {
    return StatusBadge(
      key: key,
      label: label,
      variant: StatusBadgeVariant.success,
      icon: icon,
    );
  }

  /// Factory for Pending / Review / In-Transit states
  factory StatusBadge.pending({Key? key, required String label, Widget? icon}) {
    return StatusBadge(
      key: key,
      label: label,
      variant: StatusBadgeVariant.warning,
      icon: icon,
    );
  }

  /// Factory for Urgent / Discount / Low Stock alerts
  factory StatusBadge.danger({Key? key, required String label, Widget? icon}) {
    return StatusBadge(
      key: key,
      label: label,
      variant: StatusBadgeVariant.danger,
      icon: icon,
    );
  }

  /// Factory for Neutral / Secondary badges
  factory StatusBadge.neutral({Key? key, required String label, Widget? icon}) {
    return StatusBadge(
      key: key,
      label: label,
      variant: StatusBadgeVariant.neutral,
      icon: icon,
    );
  }

  Color get _defaultBgColor {
    switch (variant) {
      case StatusBadgeVariant.verified:
        return const Color(0xFFE8F4FD);
      case StatusBadgeVariant.success:
        return AppColors.primaryLight;
      case StatusBadgeVariant.warning:
        return const Color(0xFFFEF6E9);
      case StatusBadgeVariant.danger:
        return const Color(0xFFFEEFEA);
      case StatusBadgeVariant.neutral:
        return AppColors.surfaceInput;
    }
  }

  Color get _defaultTextColor {
    switch (variant) {
      case StatusBadgeVariant.verified:
        return AppColors.info;
      case StatusBadgeVariant.success:
        return AppColors.primary;
      case StatusBadgeVariant.warning:
        return AppColors.rating;
      case StatusBadgeVariant.danger:
        return AppColors.accentWarm;
      case StatusBadgeVariant.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? _defaultBgColor;
    final effectiveText = textColor ?? _defaultTextColor;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: effectiveText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
