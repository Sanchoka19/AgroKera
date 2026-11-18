import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/order_message_model.dart';

/// Notifier managing chat conversations across orders
class OrderChatNotifier extends Notifier<Map<String, List<OrderMessage>>> {
  @override
  Map<String, List<OrderMessage>> build() {
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
