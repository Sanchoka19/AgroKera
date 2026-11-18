import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/bounce_tap.dart';
import '../../data/models/notification_model.dart';

/// Presentation card widget for a single notification item in NotificationsScreen.
/// Completely decoupled from business logic and state management.
class NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  (IconData, Color, Color) _resolveIcon() {
    switch (item.category) {
      case NotificationCategory.orders:
        if (item.isChat) {
          return (
            LucideIcons.messageCircle,
            const Color(0xFF0369A1),
            const Color(0xFFE0F2FE),
          );
        } else if (item.type == 'order_stale_farmer' ||
            item.type == 'order_stale_client' ||
            item.title.contains('PIN') ||
            item.title.contains('დამოწმება') ||
            item.title.contains('ვერ დაიხურება') ||
            item.title.contains('ჯერ არ დასრულება')) {
          return (
            LucideIcons.clockAlert,
            const Color(0xFFD97706),
            const Color(0xFFFEF3C7),
          );
        } else if (item.type == 'order_status_updated' ||
            item.title.contains('სტატუს') ||
            item.title.contains('ჩაბარდა') ||
            item.title.contains('გაუქმდა') ||
            item.title.contains('დადასტურდა')) {
          return (
            LucideIcons.truck,
            const Color(0xFF0F766E),
            const Color(0xFFCCFBF1),
          );
        } else {
          return (
            LucideIcons.package,
            const Color(0xFF0F766E),
            const Color(0xFFCCFBF1),
          );
        }
      case NotificationCategory.promotions:
        return (
          LucideIcons.tag,
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
        );
      case NotificationCategory.system:
        return (
          LucideIcons.shieldCheck,
          const Color(0xFF0284C7),
          const Color(0xFFE0F2FE),
        );
      case NotificationCategory.all:
        return (
          LucideIcons.bell,
          AppColors.primary,
          const Color(0xFFE6F4EA),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = _resolveIcon();

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'წაშლა',
              style: GoogleFonts.notoSansGeorgian(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: BounceTap(
        onTap: onTap,
        scaleDown: 0.98,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? Colors.transparent
                  : AppColors.primary.withValues(alpha: 0.20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          if (item.unreadCount > 1)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${item.unreadCount} ახალი',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.timeAgo,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

