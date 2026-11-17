import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  static final List<AppNotification> _initialTestNotifications = [
    AppNotification(
      id: 'notif-1',
      title: 'შეკვეთა #12345 მიღებულია',
      body:
          'ფერმერმა დაადასტურა თქვენი შეკვეთა და დაიწყო პროდუქტების მომზადება ტრანსპორტირებისთვის.',
      timeAgo: '12 წუთის წინ',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      category: NotificationCategory.orders,
      isRead: false,
    ),
    AppNotification(
      id: 'notif-2',
      title: 'სეზონური ფასდაკლება 20%',
      body:
          'კახური რჩეული ხილისა და ყურძნის ახალ მოსავალზე მოქმედებს სპეციალური საგაზაფხულო აქცია!',
      timeAgo: '1 საათის წინ',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      category: NotificationCategory.promotions,
      isRead: false,
    ),
    AppNotification(
      id: 'notif-3',
      title: 'ახალი შემოსული შეკვეთა #12348',
      body:
          'მომხმარებელმა გააფორმა 3 დასახელების შეკვეთა (ჯამი: ₾140). გთხოვთ დაადასტუროთ ფერმის გვერდიდან.',
      timeAgo: '3 საათის წინ',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: NotificationCategory.orders,
      isRead: true,
    ),
    AppNotification(
      id: 'notif-4',
      title: 'პროფილი ვერიფიცირებულია',
      body:
          'თქვენს პროფილს წარმატებით მიენიჭა ვერიფიცირებული სტატუსი. მადლობა AgroKera-სთან თანამშრომლობისთვის!',
      timeAgo: 'გუშინ',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: NotificationCategory.system,
      isRead: true,
    ),
    AppNotification(
      id: 'notif-5',
      title: 'შეკვეთა #12340 წარმატებით ჩაბარდა',
      body:
          'თქვენი ამანათი წარმატებით ჩაბარდა მიმღებს. გთხოვთ შეაფასოთ პროდუქტის ხარისხი.',
      timeAgo: '3 დღის წინ',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      category: NotificationCategory.orders,
      isRead: true,
    ),
  ];

  @override
  List<AppNotification> build() {
    ref.listen(authStateProvider, (prev, next) {
      if (prev?.userId != next.userId) {
        fetchNotifications();
      }
    });
    if (!isFlutterTestEnv) {
      unawaited(Future.microtask(fetchNotifications));
      return const [];
    }
    return _initialTestNotifications;
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
