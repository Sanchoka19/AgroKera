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
import '../../../../core/widgets/app_filter_tab.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../notification_navigator.dart';
import '../widgets/notification_card.dart';
import 'notification_settings_screen.dart';

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
          IconButton(
            tooltip: 'პარამეტრები',
            icon: const Icon(
              LucideIcons.slidersHorizontal,
              color: Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
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
                AppFilterTab(
                  label: 'ყველა',
                  count: allNotifications.length,
                  isSelected: _selectedCategory == NotificationCategory.all,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.all),
                ),
                const SizedBox(width: 8),
                AppFilterTab(
                  label: 'შეკვეთები',
                  count: allNotifications.where((n) => n.category == NotificationCategory.orders).length,
                  isSelected: _selectedCategory == NotificationCategory.orders,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.orders),
                ),
                const SizedBox(width: 8),
                AppFilterTab(
                  label: 'აქციები',
                  count: allNotifications.where((n) => n.category == NotificationCategory.promotions).length,
                  isSelected: _selectedCategory == NotificationCategory.promotions,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.promotions),
                ),
                const SizedBox(width: 8),
                AppFilterTab(
                  label: 'სისტემური',
                  count: allNotifications.where((n) => n.category == NotificationCategory.system).length,
                  isSelected: _selectedCategory == NotificationCategory.system,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.system),
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
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                            minWidth: constraints.maxWidth,
                          ),
                          child: _buildEmptyState(),
                        ),
                      ),
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
                        return NotificationCard(
                          item: item,
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
                          onDismiss: () {
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
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Storybook SVG illustration for Empty Notifications (matching empty_cart.svg aesthetic)
            SvgPicture.asset(
              AppAssets.emptyNotifications,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'შეტყობინებები არ არის',
              textAlign: TextAlign.center,
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
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
