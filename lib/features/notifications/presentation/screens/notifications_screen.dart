import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../notification_navigator.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  Future<void> _showFcmTokenDialog(BuildContext context) async {
    final service = PushNotificationService();
    final token = service.fcmToken ?? await service.refreshToken();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.bellRing, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'FCM Token',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ეს არის თქვენი მოწყობილობის უნიკალური ტოკენი Firebase-დან ტესტირებისთვის:',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: SelectableText(
                token ??
                    'ტოკენი მიუწვდომელია.\n\nშეცდომა: ${service.lastError ?? 'უცნობი (getToken-მა null დააბრუნა)'}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          if (token != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ტოკენი წარმატებით დაკოპირდა!',
                      style: GoogleFonts.notoSansGeorgian(),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(LucideIcons.copy, size: 16),
              label: Text(
                'კოპირება',
                style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('დახურვა', style: GoogleFonts.notoSansGeorgian()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // If user is not authenticated, show authorization required state
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'შეტყობინებები',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          actions: [
            if (kDebugMode)
              IconButton(
                tooltip: 'FCM Token',
              icon: const Icon(
                LucideIcons.bellRing,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => _showFcmTokenDialog(context),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.lock,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ავტორიზაცია აუცილებელია',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'შეტყობინებების სანახავად და სიახლეების მისაღებად გთხოვთ გაიაროთ ავტორიზაცია.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => AuthRequiredBottomSheet.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'შესვლა / რეგისტრაცია',
                      style: GoogleFonts.notoSansGeorgian(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allNotifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final filtered = allNotifications.where((n) {
      if (_selectedCategory == NotificationCategory.all) return true;
      return n.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF0F172A),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'შეტყობინებები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'FCM Token',
            icon: const Icon(
              LucideIcons.bellRing,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () => _showFcmTokenDialog(context),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: Text(
                'ყველას წაკითხვა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('ყველა', NotificationCategory.all, allNotifications.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'შეკვეთები',
                  NotificationCategory.orders,
                  allNotifications.where((n) => n.category == NotificationCategory.orders).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'აქციები',
                  NotificationCategory.promotions,
                  allNotifications.where((n) => n.category == NotificationCategory.promotions).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'სისტემური',
                  NotificationCategory.system,
                  allNotifications.where((n) => n.category == NotificationCategory.system).length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Notification List or Empty State
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).fetchNotifications(),
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: _buildEmptyState(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildNotificationCard(context, item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationCategory cat, int count) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification item) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (item.category) {
      case NotificationCategory.orders:
        if (item.type == 'chat_message' || item.title.contains('შეტყობინება')) {
          icon = LucideIcons.messageCircle;
          iconColor = const Color(0xFF0369A1);
          iconBg = const Color(0xFFE0F2FE);
        } else if (item.type == 'order_stale_farmer' ||
            item.type == 'order_stale_client' ||
            item.title.contains('ვერ დაიხურება') ||
            item.title.contains('ჯერ არ დასრულება')) {
          icon = LucideIcons.clockAlert;
          iconColor = const Color(0xFFD97706);
          iconBg = const Color(0xFFFEF3C7);
        } else if (item.type == 'order_status_updated' ||
            item.title.contains('სტატუს') ||
            item.title.contains('ჩაბარდა') ||
            item.title.contains('გაუქმდა') ||
            item.title.contains('დადასტურდა')) {
          icon = LucideIcons.truck;
          iconColor = const Color(0xFF0F766E);
          iconBg = const Color(0xFFCCFBF1);
        } else {
          icon = LucideIcons.package;
          iconColor = const Color(0xFF0F766E);
          iconBg = const Color(0xFFCCFBF1);
        }
        break;
      case NotificationCategory.promotions:
        icon = LucideIcons.tag;
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        break;
      case NotificationCategory.system:
        icon = LucideIcons.shieldCheck;
        iconColor = const Color(0xFF0284C7);
        iconBg = const Color(0xFFE0F2FE);
        break;
      case NotificationCategory.all:
        icon = LucideIcons.bell;
        iconColor = AppColors.primary;
        iconBg = const Color(0xFFE6F4EA);
        break;
    }

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
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        final removedNotif = item;
        ref.read(notificationsProvider.notifier).removeNotification(removedNotif.id);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'შეტყობინება წაიშალა',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'გაუქმება',
              textColor: const Color(0xFF34D399),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).addNotification(removedNotif);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!item.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
          }
          if (item.orderId != null) {
            NotificationNavigator.open(
              container: ProviderScope.containerOf(context, listen: false),
              navigator: Navigator.of(context),
              orderId: item.orderId,
              type: item.type,
              title: item.title,
            );
          }
        },
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
                        if (!item.isRead)
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Storybook SVG illustration for Empty Notifications (matching empty_cart.svg aesthetic)
            SvgPicture.asset(
              AppAssets.emptyNotifications,
              width: 210,
              height: 210,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'შეტყობინებები არ არის',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'სიახლეებისა და შეკვეთების შესახებ შეტყობინებები აქ გამოჩნდება.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
