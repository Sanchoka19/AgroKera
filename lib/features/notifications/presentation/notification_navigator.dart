import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_toast.dart';
import '../../orders/domain/models/farmer_order_model.dart';
import '../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../orders/presentation/screens/client_order_detail_screen.dart';
import '../../orders/presentation/screens/farmer_order_detail_screen.dart';
import '../../orders/presentation/screens/order_chat_screen.dart';

/// Where an order-related notification should lead.
enum NotificationTarget { newOrder, orderStatus, chat, unknown }

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
      case 'order_status_updated':
        return NotificationTarget.orderStatus;
      case 'chat_message':
        return NotificationTarget.chat;
      case 'order_stale_farmer':
        return NotificationTarget.newOrder; // farmer → FarmerOrderDetailScreen
      case 'order_stale_client':
        return NotificationTarget.orderStatus; // client → ClientOrderDetailScreen
    }
    final t = title ?? '';
    if (t.contains('შეტყობინება')) { return NotificationTarget.chat; }
    if (t.contains('სტატუს') || t.contains('ჩაბარდა') || t.contains('გაუქმდა') ||
        t.contains('დადასტურდა') || t.contains('PIN')) { return NotificationTarget.orderStatus; }
    if (t.contains('ახალი შეკვეთა') || t.contains('PIN კოდი ჯერ')) { return NotificationTarget.newOrder; }
    return NotificationTarget.unknown;
  }

  static FarmerOrder? _findOrder(FarmerOrdersState s, String id) {
    for (final list in [s.clientOrders, s.incomingOrders, s.orders]) {
      for (final o in list) {
        if (o.id == id) return o;
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
    final nav = navigator ?? navigatorKey.currentState;
    if (nav == null || orderId == null || orderId.isEmpty) return;

    final target = resolveTarget(type: type, title: title);
    if (target == NotificationTarget.unknown) return;

    final notifier = container.read(farmerOrdersProvider.notifier);
    var order = _findOrder(container.read(farmerOrdersProvider), orderId);
    if (order == null) {
      try {
        await notifier.refreshFromBackend();
      } catch (_) {}
      order = _findOrder(container.read(farmerOrdersProvider), orderId);
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
      case NotificationTarget.unknown:
        return;
    }

    nav.push(MaterialPageRoute(builder: (_) => screen));
  }
}

