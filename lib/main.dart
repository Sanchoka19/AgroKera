import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';
import 'core/auth/auth_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/cart_checkout/presentation/providers/cart_provider.dart';
import 'features/marketplace/presentation/providers/favorites_provider.dart';
import 'features/navigation/presentation/screens/main_nav_screen.dart';
import 'features/notifications/data/models/notification_model.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/notifications/presentation/notification_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final container = ProviderContainer();

  try {
    await PushNotificationService().initialize(
      onForegroundMessage: (remoteMessage) {
        final title = remoteMessage.notification?.title ?? 'AgroKera შეტყობინება';
        final body = remoteMessage.notification?.body ?? '';
        final categoryStr = remoteMessage.data['category'] as String?;
        final orderId = remoteMessage.data['orderId'] as String?;
        final type = remoteMessage.data['type'] as String?;
        container.read(notificationsProvider.notifier).addNotification(
              AppNotification(
                id: remoteMessage.messageId ??
                    'fcm-${DateTime.now().millisecondsSinceEpoch}',
                title: AppNotification.stripEmojis(title),
                body: body,
                timeAgo: 'ახლახანს',
                timestamp: DateTime.now(),
                category: AppNotification.parseCategory(categoryStr),
                isRead: false,
                orderId: orderId,
                type: type,
              ),
            );
        container.read(notificationsProvider.notifier).fetchNotifications();
      },
    );
    PushNotificationService().onTokenUpdated = (newToken) {
      container.read(authStateProvider.notifier).syncFcmToken(newToken);
    };
  } catch (e) {
    debugPrint('Push notification service error: $e');
  }

  await Future.wait([
    container.read(authStateProvider.notifier).restoreSession(),
    container.read(cartProvider.notifier).restoreCart(),
    container.read(favoritesProvider.notifier).restoreFavorites(),
  ]);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AgroKeraApp(),
    ),
  );

  // Open the related screen when a push notification is tapped
  PushNotificationService().onNotificationTap = (data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigator.open(
        container: container,
        orderId: data['orderId']?.toString(),
        type: data['type']?.toString(),
      );
      container.read(notificationsProvider.notifier).fetchNotifications();
    });
    WidgetsBinding.instance.scheduleFrame();
  };
}

class AgroKeraApp extends StatelessWidget {
  const AgroKeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroKera',
      navigatorKey: NotificationNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const MainNavScreen(),
    );
  }
}
