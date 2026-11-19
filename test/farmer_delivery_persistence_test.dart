import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/storage/secure_storage_service.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/profile/presentation/screens/farmer_delivery_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Disabling courier delivery persists across app restarts and provider recreation',
    (WidgetTester tester) async {
      final storage = SecureStorageService();
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );

      // Verify initial state has delivery enabled
      final initialFarmer = container
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(initialFarmer.isDeliveryEnabled, isTrue);

      // 1. Open FarmerDeliverySettingsScreen via Navigator.push so pop() works cleanly
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const FarmerDeliverySettingsScreen(farmerId: 'farmer_2'),
                      ),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Find courier delivery Switch and toggle it off
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch initialSwitch = tester.widget(switchFinder);
      expect(initialSwitch.value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final Switch toggledSwitch = tester.widget(switchFinder);
      expect(toggledSwitch.value, isFalse);

      // Save changes
      final saveBtn = find.text('ცვლილებების შენახვა');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Check in-memory state in container 1
      final updatedFarmer = container
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(updatedFarmer.isDeliveryEnabled, isFalse);

      // Verify it was persisted to SecureStorageService
      final savedSettings =
          await storage.readFarmerDeliverySettings('farmer_2');
      expect(savedSettings, isNotNull);
      expect(savedSettings!['isDeliveryEnabled'], isFalse);

      container.dispose();

      // 2. Simulate closing and relaunching the app with fresh ProviderContainer
      final newContainer = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );

      // Read provider to instantiate it and wait for async loading microtasks
      newContainer.read(marketplaceProvider);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final restoredFarmer = newContainer
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(restoredFarmer.isDeliveryEnabled, isFalse);

      // 3. Open FarmerDeliverySettingsScreen again in the new container
      await tester.pumpWidget(
        UncontrolledProviderScope(
          key: const ValueKey('reopened_app'),
          container: newContainer,
          child: const MaterialApp(
            home: FarmerDeliverySettingsScreen(farmerId: 'farmer_2'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Switch newSwitch = tester.widget(find.byType(Switch));
      expect(
        newSwitch.value,
        isFalse,
        reason:
            'Courier delivery toggle should remain inactive after app relaunch',
      );

      // 4. Test that refreshFromBackend does NOT overwrite persisted delivery settings
      await newContainer.read(marketplaceProvider.notifier).refreshFromBackend();
      final farmerAfterSync = newContainer
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(farmerAfterSync.isDeliveryEnabled, isFalse);

      newContainer.dispose();
    },
  );

  testWidgets(
    'Configuring delivery days persists across app relaunch, provider recreation, and screen re-entry',
    (WidgetTester tester) async {
      final storage = SecureStorageService();
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FarmerDeliverySettingsScreen(farmerId: 'farmer_2'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'ორშაბათი' to add it
      final mondayFinder = find.widgetWithText(FilterChip, 'ორშაბათი');
      expect(mondayFinder, findsOneWidget);
      await tester.ensureVisible(mondayFinder);
      await tester.tap(mondayFinder);
      await tester.pumpAndSettle();

      // Tap 'შაბათი' to remove it
      final saturdayFinder = find.widgetWithText(FilterChip, 'შაბათი');
      expect(saturdayFinder, findsOneWidget);
      await tester.ensureVisible(saturdayFinder);
      await tester.tap(saturdayFinder);
      await tester.pumpAndSettle();

      // Save changes
      final saveBtn = find.text('ცვლილებების შენახვა');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify in container
      final farmer = container
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(farmer.deliveryDays, contains('ორშაბათი'));
      expect(farmer.deliveryDays, isNot(contains('შაბათი')));

      // Also verify demo farmer 1 is synchronized
      final demo1Farmer = container
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_1');
      expect(demo1Farmer.deliveryDays, contains('ორშაბათი'));

      // Verify storage persistence
      final saved = await storage.readFarmerDeliverySettings('farmer_2');
      expect(saved, isNotNull);
      final savedDays = (saved!['deliveryDays'] as List).cast<String>();
      expect(savedDays, contains('ორშაბათი'));
      expect(savedDays, isNot(contains('შაბათი')));

      container.dispose();

      // Simulate app reboot
      final rebootContainer = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );

      rebootContainer.read(marketplaceProvider);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final rebootFarmer = rebootContainer
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(rebootFarmer.deliveryDays, contains('ორშაბათი'));
      expect(rebootFarmer.deliveryDays, isNot(contains('შაბათი')));

      // Re-enter screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          key: const ValueKey('reopened_screen_days'),
          container: rebootContainer,
          child: const MaterialApp(
            home: FarmerDeliverySettingsScreen(farmerId: 'farmer_2'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final FilterChip rebootMonday =
          tester.widget(find.widgetWithText(FilterChip, 'ორშაბათი'));
      expect(rebootMonday.selected, isTrue);

      final FilterChip rebootSaturday =
          tester.widget(find.widgetWithText(FilterChip, 'შაბათი'));
      expect(rebootSaturday.selected, isFalse);

      // Verify refreshFromBackend keeps persisted days
      await rebootContainer
          .read(marketplaceProvider.notifier)
          .refreshFromBackend();
      final farmerAfterRefresh = rebootContainer
          .read(marketplaceProvider)
          .farmers
          .firstWhere((f) => f.id == 'farmer_2');
      expect(farmerAfterRefresh.deliveryDays, contains('ორშაბათი'));
      expect(farmerAfterRefresh.deliveryDays, isNot(contains('შაბათი')));

      rebootContainer.dispose();
    },
  );
}
