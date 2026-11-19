import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/secure_storage_service.dart';
import 'offline_mutation.dart';

/// Single responsibility: Managing the persistence and retrieval of pending offline mutations.
class OfflineQueueStore {
  final SecureStorageService _storage;
  static const String _queueKey = 'agrokera_offline_mutations_queue';
  final List<OfflineMutation> _memoryQueue = [];

  OfflineQueueStore(this._storage);

  /// Adds a new mutation to the persistent offline queue
  Future<void> enqueue(OfflineMutation mutation) async {
    final list = List<OfflineMutation>.from(await getPendingMutations());
    // Prevent duplicate IDs
    list.removeWhere((m) => m.id == mutation.id);
    list.add(mutation);
    await _saveQueue(list);
  }

  /// Retrieves all pending mutations sorted by creation timestamp (FIFO)
  Future<List<OfflineMutation>> getPendingMutations() async {
    final raw = await _storage.readGenericString(_queueKey);
    if (raw == null || raw.trim().isEmpty) {
      return List.unmodifiable(_memoryQueue);
    }
    try {
      final decoded = jsonDecode(raw) as List;
      final parsed = decoded
          .whereType<Map<String, dynamic>>()
          .map(OfflineMutation.fromJson)
          .toList();
      _memoryQueue
        ..clear()
        ..addAll(parsed);
      _memoryQueue.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return List.unmodifiable(_memoryQueue);
    } catch (_) {
      return List.unmodifiable(_memoryQueue);
    }
  }

  /// Removes a successfully processed mutation from the queue
  Future<void> remove(String mutationId) async {
    final list = List<OfflineMutation>.from(await getPendingMutations());
    final updated = list.where((m) => m.id != mutationId).toList();
    await _saveQueue(updated);
  }

  /// Increments retry count for a failed mutation
  Future<void> incrementRetry(String mutationId) async {
    final list = List<OfflineMutation>.from(await getPendingMutations());
    final updated = list.map((m) {
      if (m.id == mutationId) {
        return m.copyWith(retryCount: m.retryCount + 1);
      }
      return m;
    }).toList();
    await _saveQueue(updated);
  }

  /// Returns total count of pending offline actions
  Future<int> count() async {
    final items = await getPendingMutations();
    return items.length;
  }

  /// Clears the queue
  Future<void> clear() async {
    _memoryQueue.clear();
    await _storage.deleteGenericString(_queueKey);
  }

  Future<void> _saveQueue(List<OfflineMutation> list) async {
    _memoryQueue
      ..clear()
      ..addAll(list);
    final jsonStr = jsonEncode(list.map((m) => m.toJson()).toList());
    await _storage.saveGenericString(_queueKey, jsonStr);
  }
}

/// Riverpod provider for OfflineQueueStore
final offlineQueueStoreProvider = Provider<OfflineQueueStore>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return OfflineQueueStore(storage);
});
