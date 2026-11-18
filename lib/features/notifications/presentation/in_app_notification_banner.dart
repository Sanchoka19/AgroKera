import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/widgets/app_toast.dart';
import 'notification_navigator.dart';
import 'providers/notification_settings_provider.dart';

/// Shows an interactive top-floating in-app toast banner when a notification
/// arrives while the user is actively using the application.
class InAppNotificationBanner {
  InAppNotificationBanner._();

  static void showIfEnabled({
    required ProviderContainer container,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final type = data['type']?.toString();
    final orderId = data['orderId']?.toString();
    final category = data['category']?.toString();

    // 1. If user is currently looking at this order's chat screen, suppress toast
    if (type == 'chat_message' &&
        orderId != null &&
        orderId == PushNotificationService.activeChatOrderId) {
      return;
    }

    // 2. Check user notification settings
    final settings = container.read(notificationSettingsProvider);
    if (!settings.inAppToastEnabled) return;
    if (!settings.shouldDeliver(category: category, type: type)) return;

    // 3. Resolve context from global navigatorKey
    final context = NotificationNavigator.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final isChat = type == 'chat_message' || title.contains('შეტყობინება');
    final icon = isChat
        ? LucideIcons.messageCircle
        : category == 'promotions'
            ? LucideIcons.tag
            : LucideIcons.packageCheck;

    final toastMessage = body.isNotEmpty ? '$title\n$body' : title;

    AppToast.show(
      context,
      toastMessage,
      type: ToastType.info,
      icon: icon,
      duration: const Duration(seconds: 4),
      actionLabel: 'ნახვა',
      sendToBell: true,
      onAction: () {
        NotificationNavigator.open(
          container: container,
          orderId: orderId,
          type: type,
          title: title,
        );
      },
    );
  }
}

