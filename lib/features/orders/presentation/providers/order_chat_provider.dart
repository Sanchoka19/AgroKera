import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../domain/models/farmer_order_model.dart';
import '../../domain/models/order_message_model.dart';
import 'farmer_orders_provider.dart';

/// Notifier managing chat conversations across orders
class OrderChatNotifier extends Notifier<Map<String, List<OrderMessage>>> {
  @override
  Map<String, List<OrderMessage>> build() {
    ref.listen(authStateProvider, (prev, next) {
      if (prev?.userId != next.userId) {
        state = const {};
      }
    });
    return const {};
  }

  Future<void> loadMessages(String orderId) async {
    // 1. Fast cache load from local storage
    try {
      final storage = ref.read(secureStorageProvider);
      final cachedJson = await storage.readOrderMessagesJson(orderId);
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        final messages = decoded
            .whereType<Map<String, dynamic>>()
            .map(OrderMessage.fromJson)
            .toList();
        if (messages.isNotEmpty) {
          state = {...state, orderId: messages};
        }
      }
    } catch (_) {
      // Gracefully maintain state on storage or format errors
    }

    // 2. Default fallback system message if completely empty
    if (!state.containsKey(orderId) || state[orderId]!.isEmpty) {
      final initialMessage = OrderMessage(
        id: 'sys_$orderId',
        orderId: orderId,
        senderId: 'system',
        senderRole: UserRole.guest,
        senderName: 'AgroKera System',
        text: 'შეკვეთის ჩათი გააქტიურდა. გამოიყენეთ მისამართისა და ჩაბარების დროის დასაზუსტებლად.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isSystem: true,
      );

      final initialList = [initialMessage];
      state = {...state, orderId: initialList};
      unawaited(_persist(orderId, initialList));
    }

    // 3. Live sync from backend API
    await syncMessages(orderId);
  }

  Future<void> syncMessages(String orderId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<List<dynamic>>('/api/orders/$orderId/messages');
      if (res.data != null && res.data is List) {
        final remoteMessages = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(OrderMessage.fromJson)
            .toList();

        if (remoteMessages.isNotEmpty) {
          final current = state[orderId] ?? const [];
          final remoteIds = remoteMessages.map((m) => m.id).toSet();
          final localUnsynced =
              current.where((m) => !remoteIds.contains(m.id)).toList();

          final merged = [...remoteMessages, ...localUnsynced]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          state = {...state, orderId: merged};
          unawaited(_persist(orderId, merged));
        }
      }
    } catch (_) {
      // Gracefully maintain state on network or test environment errors
    }
  }

  Future<void> sendMessage({
    required String orderId,
    required String text,
    required String senderId,
    required UserRole senderRole,
    required String senderName,
    OrderMessageType type = OrderMessageType.text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final currentMessages = state[orderId] ?? const [];
    final message = OrderMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      orderId: orderId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      text: cleanText,
      type: type,
      createdAt: DateTime.now(),
    );

    final updated = [...currentMessages, message];
    state = {...state, orderId: updated};
    unawaited(_persist(orderId, updated));
    unawaited(_syncMessageToBackend(orderId, message));
  }

  Future<void> _persist(String orderId, List<OrderMessage> messages) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final jsonStr = jsonEncode(messages.map((m) => m.toJson()).toList());
      await storage.saveOrderMessagesJson(orderId, jsonStr);
    } catch (_) {}
  }

  Future<void> _syncMessageToBackend(String orderId, OrderMessage message) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/api/orders/$orderId/messages',
        data: message.toJson(),
      );
      unawaited(syncMessages(orderId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Chat is locked (order not yet confirmed or already completed).
        // Roll back the optimistic message.
        final current = state[orderId] ?? [];
        final rolled = current.where((m) => m.id != message.id).toList();
        state = {...state, orderId: rolled};
        rethrow; // let the UI catch and show the reason
      }
      // Other network errors – silently ignore (offline, timeout, etc.)
    } catch (_) {}
  }
}

final orderChatProvider =
    NotifierProvider<OrderChatNotifier, Map<String, List<OrderMessage>>>(
  OrderChatNotifier.new,
);

/// Tracks the last read timestamp per order chat in the current session
class OrderChatReadNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    ref.listen(authStateProvider, (prev, next) {
      if (prev?.userId != next.userId) {
        state = const {};
      }
    });
    return const {};
  }

  /// Marks all messages and chat notifications for [orderId] as read
  void markAsRead(String orderId) {
    state = {...state, orderId: DateTime.now()};
    unawaited(
      ref
          .read(notificationsProvider.notifier)
          .markOrderChatNotificationsAsRead(orderId),
    );
  }
}

final orderChatReadProvider =
    NotifierProvider<OrderChatReadNotifier, Map<String, DateTime>>(
  OrderChatReadNotifier.new,
);

/// Determines whether a specific order's chat has unread messages for the current user.
/// Only active orders (`pending` or `inProgress`) can show an unread indicator;
/// `completed` and `cancelled` chats never trigger unread reactions.
final isOrderChatUnreadProvider = Provider.family<bool, String>((ref, orderId) {
  final auth = ref.watch(authStateProvider);
  if (!auth.isAuthenticated) return false;

  final ordersState = ref.watch(farmerOrdersProvider);
  final order = ordersState.orders.where((o) => o.id == orderId).firstOrNull ??
      ordersState.incomingOrders.where((o) => o.id == orderId).firstOrNull ??
      ordersState.clientOrders.where((o) => o.id == orderId).firstOrNull;

  if (order != null &&
      (order.status == OrderStatus.completed ||
          order.status == OrderStatus.cancelled)) {
    return false;
  }

  final myRole = auth.role;
  final readMap = ref.watch(orderChatReadProvider);
  final lastRead = readMap[orderId];

  // 1. Check unread chat notifications from notificationsProvider
  final notifications = ref.watch(notificationsProvider);
  final hasUnreadNotif = notifications.any(
    (n) => n.isChat && !n.isRead && n.orderId == orderId,
  );
  if (hasUnreadNotif) return true;

  // 2. Check counterparty messages in orderChatProvider
  final chatMap = ref.watch(orderChatProvider);
  final messages = chatMap[orderId];
  if (messages == null || messages.isEmpty) return false;

  return messages.any(
    (m) =>
        !m.isSystem &&
        m.senderRole != myRole &&
        (lastRead == null || m.createdAt.isAfter(lastRead)),
  );
});

/// Total count of unread chat messages/conversations for the logged-in user (Farmer or Customer).
/// Counts ONLY active orders (`pending` or `inProgress`). Completed and cancelled chats are ignored.
final unreadChatCountProvider = Provider<int>((ref) {
  final auth = ref.watch(authStateProvider);
  if (!auth.isAuthenticated) return 0;

  final myRole = auth.role;
  final isFarmer = myRole == UserRole.farmer;
  final ordersState = ref.watch(farmerOrdersProvider);
  final myOrders =
      isFarmer ? ordersState.incomingOrders : ordersState.clientOrders;

  final chatMap = ref.watch(orderChatProvider);
  final readMap = ref.watch(orderChatReadProvider);
  final notifications = ref.watch(notificationsProvider);

  int totalUnread = 0;

  // Count strictly from user's active orders (Pending / InProgress)
  for (final order in myOrders) {
    final isActive =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.inProgress;
    if (!isActive) continue;

    final lastRead = readMap[order.id];
    final messages = chatMap[order.id] ?? const [];

    final unreadMsgsInChat = messages
        .where(
          (m) =>
              !m.isSystem &&
              m.senderRole != myRole &&
              (lastRead == null || m.createdAt.isAfter(lastRead)),
        )
        .length;

    final unreadNotifsForOrder = notifications
        .where((n) => n.isChat && !n.isRead && n.orderId == order.id)
        .fold<int>(0, (sum, n) => sum + n.unreadCount);

    final orderUnread = max(unreadMsgsInChat, unreadNotifsForOrder);
    if (orderUnread > 0) {
      totalUnread += orderUnread;
    }
  }

  return totalUnread;
});

/// Utility to sort order conversations based on urgency and activity recency
abstract class OrderChatSorter {
  /// Sort active orders by unread status first, then urgency (pending first), then newest message/activity
  static List<FarmerOrder> sortByUrgencyAndActivity(
    List<FarmerOrder> orders,
    Map<String, List<OrderMessage>> chatMap, {
    Set<String> unreadOrderIds = const {},
  }) {
    final list = List<FarmerOrder>.from(orders);
    list.sort((a, b) {
      // 0. Unread conversations take highest priority
      final aUnread = unreadOrderIds.contains(a.id);
      final bUnread = unreadOrderIds.contains(b.id);
      if (aUnread != bUnread) {
        return aUnread ? -1 : 1;
      }

      // 1. Pending orders take top priority (requires farmer/buyer immediate response)
      if (a.status == OrderStatus.pending && b.status != OrderStatus.pending) {
        return -1;
      }
      if (b.status == OrderStatus.pending && a.status != OrderStatus.pending) {
        return 1;
      }

      // 2. Latest message or order creation timestamp
      final aMsgs = chatMap[a.id];
      final bMsgs = chatMap[b.id];
      final aDate = (aMsgs != null && aMsgs.isNotEmpty)
          ? aMsgs.last.createdAt
          : a.createdAt;
      final bDate = (bMsgs != null && bMsgs.isNotEmpty)
          ? bMsgs.last.createdAt
          : b.createdAt;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  /// Sort orders strictly by newest message or creation timestamp
  static List<FarmerOrder> sortByLatestActivity(
    List<FarmerOrder> orders,
    Map<String, List<OrderMessage>> chatMap,
  ) {
    final list = List<FarmerOrder>.from(orders);
    list.sort((a, b) {
      final aMsgs = chatMap[a.id];
      final bMsgs = chatMap[b.id];
      final aDate = (aMsgs != null && aMsgs.isNotEmpty)
          ? aMsgs.last.createdAt
          : a.createdAt;
      final bDate = (bMsgs != null && bMsgs.isNotEmpty)
          ? bMsgs.last.createdAt
          : b.createdAt;
      return bDate.compareTo(aDate);
    });
    return list;
  }
}

