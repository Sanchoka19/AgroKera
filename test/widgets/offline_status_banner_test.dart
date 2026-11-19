import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/network/connectivity/network_connectivity_service.dart';
import 'package:agrokera/core/widgets/offline_status_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineStatusBanner Widget Tests', () {
    testWidgets('hides completely when network is online and idle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OfflineStatusBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.textContaining('ოფლაინ რეჟიმი'), findsNothing);
    });

    testWidgets('renders warning banner and Lucide wifiOff icon when offline', (
      tester,
    ) async {
      final connectivity = NetworkConnectivityService();
      connectivity.setStatusForTesting(NetworkStatus.offline);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineStatusBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ოფლაინ რეჟიმი • ცვლილებები შეინახება ლოკალურად'), findsOneWidget);
      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);

      connectivity.dispose();
    });
  });
}
