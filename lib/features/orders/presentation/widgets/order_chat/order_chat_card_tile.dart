import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/farmer_order_model.dart';
import '../../../domain/models/order_message_model.dart';

/// Presentation card tile representing an order chat conversation in the list
class OrderChatCardTile extends StatelessWidget {
  final FarmerOrder order;
  final OrderMessage? lastMessage;
  final bool isFarmer;
  final bool hasUnread;
  final VoidCallback onTap;

  const OrderChatCardTile({
    super.key,
    required this.order,
    this.lastMessage,
    required this.isFarmer,
    this.hasUnread = false,
    required this.onTap,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'იან',
      'თებ',
      'მარ',
      'აპრ',
      'მაი',
      'ივნ',
      'ივლ',
      'აგვ',
      'სექ',
      'ოქტ',
      'ნოე',
      'დეკ'
    ];
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return '$h:$min';
    }
    final m = months[dt.month - 1];
    return '${dt.day} $m, $h:$min';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.inProgress;
    final isPending = order.status == OrderStatus.pending;

    // Display title based on role
    final titleText = isFarmer
        ? order.customerName
        : (order.contactPerson.isNotEmpty &&
                order.contactPerson != 'მყიდველი'
            ? order.contactPerson
            : 'შეკვეთა #${_shortId(order.id)}');

    final displayTime = _formatDate(lastMessage?.createdAt ?? order.createdAt);

    // Border styling
    final Border borderStyle;
    if (isPending) {
      borderStyle = Border.all(
        color: const Color(0xFFD97706).withValues(alpha: 0.35),
        width: 1.5,
      );
    } else if (isActive) {
      borderStyle = Border.all(
        color: AppColors.primary.withValues(alpha: 0.25),
        width: 1.5,
      );
    } else {
      borderStyle = Border.all(
        color: const Color(0xFFE2E8F0),
        width: 1.0,
      );
    }

    // Avatar styling
    final Color avatarBg;
    final Color avatarIconColor;
    if (isPending) {
      avatarBg = const Color(0xFFFEF3C7);
      avatarIconColor = const Color(0xFFD97706);
    } else if (isActive) {
      avatarBg = AppColors.primary.withValues(alpha: 0.1);
      avatarIconColor = AppColors.primary;
    } else if (order.status == OrderStatus.completed) {
      avatarBg = const Color(0xFFE8F7EE);
      avatarIconColor = const Color(0xFF16A34A);
    } else {
      avatarBg = const Color(0xFFF1F5F9);
      avatarIconColor = const Color(0xFF64748B);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: borderStyle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with active/pending indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarIconColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isFarmer ? LucideIcons.user : LucideIcons.store,
                      size: 22,
                      color: avatarIconColor,
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFD97706)
                              : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Chat Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Title & Time + Unread dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 15,
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayTime,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Products summary & total
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${order.productsSummary} • ${order.totalAmount.toStringAsFixed(1)} ₾',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Last message preview & Status pill
                    Row(
                      children: [
                        Icon(
                          lastMessage?.isSystem == true
                              ? LucideIcons.shieldAlert
                              : LucideIcons.messageSquare,
                          size: 13,
                          color: isPending
                              ? const Color(0xFFD97706)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lastMessage != null
                                ? (lastMessage!.isSystem
                                    ? 'სისტემა: ${lastMessage!.text}'
                                    : '${lastMessage!.senderName}: ${lastMessage!.text}')
                                : 'დააჭირეთ მიმოწერის დასაწყებად...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              fontWeight: lastMessage != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: lastMessage != null
                                  ? const Color(0xFF334155)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: order.status.badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.label,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: order.status.color,
                            ),
                          ),
                        ),
                      ],
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
