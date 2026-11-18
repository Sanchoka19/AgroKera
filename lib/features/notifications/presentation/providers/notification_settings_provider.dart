import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/notification_settings_repository.dart';
import '../../domain/models/notification_settings_model.dart';

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return NotificationSettingsRepository(storage);
});

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  late final NotificationSettingsRepository _repo;

  @override
  NotificationSettings build() {
    _repo = ref.watch(notificationSettingsRepositoryProvider);
    unawaited(_loadInitialSettings());
    return const NotificationSettings();
  }

  Future<void> _loadInitialSettings() async {
    final loaded = await _repo.loadSettings();
    state = loaded;
  }

  Future<void> toggleOrders(bool value) async {
    state = state.copyWith(ordersEnabled: value);
    await _repo.saveSettings(state);
  }

  Future<void> toggleChat(bool value) async {
    state = state.copyWith(chatEnabled: value);
    await _repo.saveSettings(state);
  }

  Future<void> togglePromotions(bool value) async {
    state = state.copyWith(promotionsEnabled: value);
    await _repo.saveSettings(state);
  }

  Future<void> toggleInAppToast(bool value) async {
    state = state.copyWith(inAppToastEnabled: value);
    await _repo.saveSettings(state);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

