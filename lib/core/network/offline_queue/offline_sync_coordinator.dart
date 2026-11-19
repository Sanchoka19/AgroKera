import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../connectivity/network_connectivity_service.dart';
import 'offline_mutation.dart';
import 'offline_queue_store.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Single responsibility: Orchestrating the synchronization of pending offline mutations
/// when internet connection is restored or when manually requested.
class OfflineSyncCoordinator {
  final ApiClient apiClient;
  final OfflineQueueStore queueStore;
  final NetworkConnectivityService connectivityService;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  StreamSubscription<NetworkStatus>? _networkSubscription;
  bool _isProcessing = false;
  final List<void Function()> _onSyncCompletedListeners = [];

  OfflineSyncCoordinator({
    required this.apiClient,
    required this.queueStore,
    required this.connectivityService,
  }) {
    _networkSubscription =
        connectivityService.onStatusChanged.listen((status) {
      if (status == NetworkStatus.online) {
        unawaited(syncPendingMutations());
      }
    });
  }

  Stream<SyncStatus> get onSyncStatusChanged => _statusController.stream;

  void addOnSyncCompletedListener(void Function() listener) {
    _onSyncCompletedListeners.add(listener);
  }

  void removeOnSyncCompletedListener(void Function() listener) {
    _onSyncCompletedListeners.remove(listener);
  }

  /// Processes all pending mutations in the queue sequentially.
  Future<bool> syncPendingMutations() async {
    if (_isProcessing) return false;
    _isProcessing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final mutations = await queueStore.getPendingMutations();
      if (mutations.isEmpty) {
        _statusController.add(SyncStatus.idle);
        _isProcessing = false;
        return true;
      }

      for (final mutation in mutations) {
        final success = await _dispatchMutation(mutation);
        if (success) {
          await queueStore.remove(mutation.id);
        } else {
          await queueStore.incrementRetry(mutation.id);
          // If we fail on one network error while syncing, stop queue processing until next reconnect
          if (connectivityService.lastKnownStatus == NetworkStatus.offline) {
            break;
          }
        }
      }

      final remaining = await queueStore.count();
      if (remaining == 0) {
        _statusController.add(SyncStatus.success);
        for (final listener in _onSyncCompletedListeners) {
          try {
            listener();
          } catch (_) {}
        }
      } else {
        _statusController.add(SyncStatus.error);
      }
      return remaining == 0;
    } catch (_) {
      _statusController.add(SyncStatus.error);
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _dispatchMutation(OfflineMutation mutation) async {
    try {
      switch (mutation.method.toUpperCase()) {
        case 'POST':
          final res = await apiClient.post(
            mutation.endpoint,
            data: mutation.payload,
          );
          return res.statusCode != null && res.statusCode! < 300;
        case 'PATCH':
          final res = await apiClient.patch(
            mutation.endpoint,
            data: mutation.payload,
          );
          return res.statusCode != null && res.statusCode! < 300;
        case 'DELETE':
          final res = await apiClient.delete(mutation.endpoint);
          return res.statusCode != null && res.statusCode! < 300;
        default:
          return false;
      }
    } on DioException catch (e) {
      // 4xx errors (except 408 / 429) mean request is invalid; remove to prevent poison pill
      final code = e.response?.statusCode;
      if (code != null && code >= 400 && code < 500 && code != 408 && code != 429) {
        return true; // Consider handled to discard poison pill
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _networkSubscription?.cancel();
    _statusController.close();
    _onSyncCompletedListeners.clear();
  }
}

/// Riverpod provider for OfflineSyncCoordinator
final offlineSyncCoordinatorProvider = Provider<OfflineSyncCoordinator>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final queueStore = ref.watch(offlineQueueStoreProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  final coordinator = OfflineSyncCoordinator(
    apiClient: apiClient,
    queueStore: queueStore,
    connectivityService: connectivity,
  );

  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Reactive stream provider for sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final coordinator = ref.watch(offlineSyncCoordinatorProvider);
  return coordinator.onSyncStatusChanged;
});
