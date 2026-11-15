import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
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
    if (state.containsKey(orderId) && state[orderId]!.isNotEmpty) return;

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
          return;
        }
      }

      // Default system message introducing the chat
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
      await _persist(orderId, initialList);
    } catch (_) {
      // Gracefully maintain state on storage or format errors
    }
  }

  Future<void> sendMessage({
    required String orderId,
    required String text,
    required String senderId,
    required UserRole senderRole,
    required String senderName,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final currentMessages = state[orderId] ?? const [];
    final message = OrderMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: orderId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      text: cleanText,
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
    } catch (_) {
      // Gracefully ignore network errors in tests/offline
    }
  }
}

final orderChatProvider =
    NotifierProvider<OrderChatNotifier, Map<String, List<OrderMessage>>>(
  OrderChatNotifier.new,
);
