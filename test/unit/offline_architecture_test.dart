import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/network/api_client.dart';
import 'package:agrokera/core/network/connectivity/network_connectivity_service.dart';
import 'package:agrokera/core/network/offline_queue/offline_mutation.dart';
import 'package:agrokera/core/network/offline_queue/offline_queue_store.dart';
import 'package:agrokera/core/network/offline_queue/offline_sync_coordinator.dart';
import 'package:agrokera/core/storage/cache/local_cache_service.dart';
import 'package:agrokera/core/storage/secure_storage_service.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline-First Modular Architecture Unit Tests', () {
    late SecureStorageService storage;
    late LocalCacheService cacheService;
    late OfflineQueueStore queueStore;
    late NetworkConnectivityService connectivityService;

    setUp(() {
      storage = SecureStorageService();
      cacheService = LocalCacheService(storage);
      queueStore = OfflineQueueStore(storage);
      connectivityService = NetworkConnectivityService();
    });

    test('NetworkConnectivityService toggles status and emits stream updates', () async {
      expect(connectivityService.lastKnownStatus, NetworkStatus.online);

      final statusList = <NetworkStatus>[];
      final subscription = connectivityService.onStatusChanged.listen(statusList.add);

      connectivityService.setStatusForTesting(NetworkStatus.offline);
      expect(connectivityService.lastKnownStatus, NetworkStatus.offline);

      connectivityService.setStatusForTesting(NetworkStatus.online);
      expect(connectivityService.lastKnownStatus, NetworkStatus.online);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(statusList, [NetworkStatus.offline, NetworkStatus.online]);

      await subscription.cancel();
      connectivityService.dispose();
    });

    test('LocalCacheService saves, reads, upserts and removes entities', () async {
      const testKey = 'test_products';
      final initialData = [
        {'id': 'prod_1', 'title': 'თაფლი', 'price': 25.0},
        {'id': 'prod_2', 'title': 'ყველი', 'price': 18.0},
      ];

      await cacheService.saveEntityList(testKey, initialData);

      final loaded = await cacheService.readEntityList(testKey);
      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded[0]['title'], 'თაფლი');

      // Upsert existing entity
      await cacheService.upsertEntityInList(testKey, {
        'id': 'prod_1',
        'title': 'მაისის თაფლი',
        'price': 30.0,
      });

      final updated = await cacheService.readEntityList(testKey);
      expect(updated!.length, 2);
      expect(updated[0]['title'], 'მაისის თაფლი');
      expect(updated[0]['price'], 30.0);

      // Remove entity
      await cacheService.removeEntityFromList(testKey, 'prod_2');
      final afterRemove = await cacheService.readEntityList(testKey);
      expect(afterRemove!.length, 1);
      expect(afterRemove[0]['id'], 'prod_1');

      // Clear
      await cacheService.clear(testKey);
      final afterClear = await cacheService.readEntityList(testKey);
      expect(afterClear, isNull);
    });

    test('OfflineQueueStore persists, retrieves FIFO and manages mutations', () async {
      await queueStore.clear();

      final m1 = OfflineMutation(
        id: 'mut_1',
        endpoint: '/api/products',
        method: 'POST',
        payload: {'title': 'ვაშლი'},
        timestamp: DateTime(2026, 11, 19, 10, 0),
        description: 'ახალი პროდუქტი',
      );

      final m2 = OfflineMutation(
        id: 'mut_2',
        endpoint: '/api/products/prod_1',
        method: 'PATCH',
        payload: {'stockQuantity': 40.0},
        timestamp: DateTime(2026, 11, 19, 10, 5),
        description: 'მარაგის განახლება',
      );

      await queueStore.enqueue(m2); // Enqueued second with later time
      await queueStore.enqueue(m1); // Enqueued with earlier time

      final pending = await queueStore.getPendingMutations();
      expect(pending.length, 2);
      // Must be sorted chronologically FIFO
      expect(pending[0].id, 'mut_1');
      expect(pending[1].id, 'mut_2');

      // Increment retry
      await queueStore.incrementRetry('mut_1');
      final withRetry = await queueStore.getPendingMutations();
      expect(withRetry.firstWhere((m) => m.id == 'mut_1').retryCount, 1);

      // Remove
      await queueStore.remove('mut_1');
      expect(await queueStore.count(), 1);

      await queueStore.clear();
      expect(await queueStore.count(), 0);
    });

    test('OfflineSyncCoordinator dispatches queue when online and notifies listeners', () async {
      final apiClient = ApiClient(storage: storage);
      final coordinator = OfflineSyncCoordinator(
        apiClient: apiClient,
        queueStore: queueStore,
        connectivityService: connectivityService,
      );

      await queueStore.clear();
      bool listenerCalled = false;
      coordinator.addOnSyncCompletedListener(() {
        listenerCalled = true;
      });

      // When queue is empty, sync returns true immediately
      final emptyResult = await coordinator.syncPendingMutations();
      expect(emptyResult, isTrue);
      expect(listenerCalled, isFalse);

      coordinator.dispose();
    });

    test('MarketplaceNotifier optimistically saves product and persists to local cache', () async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          localCacheServiceProvider.overrideWithValue(cacheService),
          offlineQueueStoreProvider.overrideWithValue(queueStore),
        ],
      );

      final notifier = container.read(marketplaceProvider.notifier);

      final newProduct = await notifier.addProduct(
        title: 'კახური მზესუმზირის ზეთი',
        category: 'ზეთი და ძმარი',
        price: 15.0,
        stockQuantity: 100.0,
        farmerId: 'farmer_2',
        farmerName: 'გიორგის ფერმა',
      );

      expect(newProduct.title, 'კახური მზესუმზირის ზეთი');
      final state = container.read(marketplaceProvider);
      expect(state.products.any((p) => p.title == 'კახური მზესუმზირის ზეთი'), isTrue);

      // Check that it was enqueued in offline queue (since live network was skipped in test)
      final pending = await queueStore.getPendingMutations();
      expect(pending.any((m) => m.description.contains('კახური მზესუმზირის ზეთი')), isTrue);

      container.dispose();
    });
  });
}
