import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    ref.listen(authStateProvider, (prev, next) {
      if (prev?.userId != next.userId) {
        fetchNotifications();
      }
    });
    unawaited(Future.microtask(fetchNotifications));
    return const [];
  }

  Future<void> fetchNotifications() async {
    final auth = ref.read(authStateProvider);
    final userId = auth.userId;
    if (userId == null || !auth.isAuthenticated) {
      state = const [];
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(
        '/api/notifications',
        queryParameters: {'userId': userId},
      );
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) =>
                AppNotification.fromJson(item as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (e) {
      // Keep existing state on transient network failures
    }
  }

  void addNotification(AppNotification notif) {
    // Check if notif with same id already exists
    if (state.any((n) => n.id == notif.id)) return;
    state = [notif, ...state];
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final notif in state)
        if (notif.id == id) notif.copyWith(isRead: true) else notif,
    ];
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/api/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    state = [
      for (final notif in state) notif.copyWith(isRead: true),
    ];
    try {
      final auth = ref.read(authStateProvider);
      if (auth.userId != null) {
        final api = ref.read(apiClientProvider);
        await api.patch(
          '/api/notifications/read-all',
          data: {'userId': auth.userId},
        );
      }
    } catch (_) {}
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = const [];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});
