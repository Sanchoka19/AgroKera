import 'dart:convert';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/models/notification_settings_model.dart';

/// Repository for persisting and retrieving user notification preferences
class NotificationSettingsRepository {
  final SecureStorageService _storage;

  NotificationSettingsRepository(this._storage);

  Future<NotificationSettings> loadSettings() async {
    try {
      final raw = await _storage.readNotificationSettingsJson();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return NotificationSettings.fromJson(decoded);
      }
    } catch (_) {}
    return const NotificationSettings();
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      await _storage.saveNotificationSettingsJson(jsonEncode(settings.toJson()));
    } catch (_) {}
  }
}

