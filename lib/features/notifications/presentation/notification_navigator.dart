import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_toast.dart';
import '../../orders/domain/models/farmer_order_model.dart';
import '../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../orders/presentation/screens/client_order_detail_screen.dart';
import '../../orders/presentation/screens/farmer_order_detail_screen.dart';
import '../../orders/presentation/screens/order_chat_screen.dart';
import '../../reviews/presentation/screens/farmer_my_reviews_screen.dart';

/// Where an order-related notification should lead.
enum NotificationTarget { newOrder, orderStatus, chat, review, unknown }

/// Opens the screen that a notification belongs to.
///
/// - "ახალი შეკვეთა მიღებულია!"   (order_created)        → ფერმერის შეკვეთის დეტალები
/// - "შეკვეთის სტატუსი განახლდა!" (order_status_updated) → კლიენტის შეკვეთის დეტალები
/// - "ახალი შეტყობინება (...)"     (chat_message)         → შეკვეთის ჩატი
class NotificationNavigator {
  NotificationNavigator._();

  /// Global navigator key, used when a push notification is tapped
  /// (outside of any widget's BuildContext).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NotificationTarget resolveTarget({String? type, String? title}) {
    switch (type) {
      case 'order_created':
        return NotificationTarget.newOrder;
      case 'order_created_client':
        return NotificationTarget.orderStatus;
      case 'order_status_updated':
        return NotificationTarget.orderStatus;
      case 'chat_message':
        return NotificationTarget.chat;
      case 'farmer_review_received':
      case 'review_received':
        return NotificationTarget.review;
      case 'order_stale_farmer':
        return NotificationTarget.newOrder; // farmer → FarmerOrderDetailScreen
      case 'order_stale_client':
        return NotificationTarget.orderStatus; // client → ClientOrderDetailScreen
    }
    final t = title ?? '';
    if (t.contains('შეფასებ')) { return NotificationTarget.review; }
    if (t.contains('შეტყობინება')) { return NotificationTarget.chat; }
    if (t.contains('სტატუს') || t.contains('ჩაბარდა') || t.contains('გაუქმდა') ||
        t.contains('დადასტურდა') || t.contains('PIN') || t.contains('გაფორმდა')) { return NotificationTarget.orderStatus; }
    if (t.contains('ახალი შეკვეთა') || t.contains('PIN კოდი ჯერ')) { return NotificationTarget.newOrder; }
    return NotificationTarget.orderStatus; // default to order status when orderId is known
  }

  static FarmerOrder? _findOrder(FarmerOrdersState s, String id) {
    for (final list in [s.clientOrders, s.incomingOrders, s.orders]) {
      for (final o in list) {
        if (o.id == id || o.id.endsWith(id) || id.endsWith(o.id)) return o;
      }
    }
    return null;
  }

  /// Opens the target screen. [container] is the app's ProviderContainer.
  static Future<void> open({
    required ProviderContainer container,
    required String? orderId,
    String? type,
    String? title,
    NavigatorState? navigator,
  }) async {
    NavigatorState? nav = navigator ?? navigatorKey.currentState;
    if (nav == null) {
      // If the app was opened from closed state, wait for navigatorKey to mount
      for (int i = 0; i < 20 && nav == null; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        nav = navigator ?? navigatorKey.currentState;
      }
    }
    if (nav == null || orderId == null || orderId.isEmpty) return;

    final target = resolveTarget(type: type, title: title);
    if (target == NotificationTarget.unknown) return;

    if (target == NotificationTarget.review) {
      nav.push(MaterialPageRoute(builder: (_) => const FarmerMyReviewsScreen()));
      return;
    }

    final notifier = container.read(farmerOrdersProvider.notifier);
    var order = _findOrder(container.read(farmerOrdersProvider), orderId);
    if (order == null) {
      try {
        await notifier.refreshFromBackend();
      } catch (_) {}
      order = _findOrder(container.read(farmerOrdersProvider), orderId);
    }

    if (order == null) {
      try {
        final api = container.read(apiClientProvider);
        final res = await api.get<List<dynamic>>('/api/orders');
        if (res.data != null) {
          final list = res.data!
              .whereType<Map<String, dynamic>>()
              .map(FarmerOrder.fromJson)
              .toList();
          for (final o in list) {
            if (o.id == orderId || o.id.endsWith(orderId) || orderId.endsWith(o.id)) {
              order = o;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (order == null) {
      final ctx = nav.context;
      if (ctx.mounted) {
        AppToast.error(ctx, 'შეკვეთა ვერ მოიძებნა');
      }
      return;
    }

    final Widget screen;
    switch (target) {
      case NotificationTarget.newOrder:
        screen = FarmerOrderDetailScreen(orderId: order.id);
        break;
      case NotificationTarget.orderStatus:
        screen = ClientOrderDetailScreen(orderId: order.id);
        break;
      case NotificationTarget.chat:
        screen = OrderChatScreen(order: order);
        break;
      case NotificationTarget.review:
        screen = const FarmerMyReviewsScreen();
        break;
      case NotificationTarget.unknown:
        return;
    }

    nav.push(MaterialPageRoute(builder: (_) => screen));
  }
}

