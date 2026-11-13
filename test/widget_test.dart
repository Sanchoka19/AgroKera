import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/main.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/widgets/app_logo.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'package:agrokera/features/navigation/presentation/screens/main_nav_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('AgroKera Guest Mode smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgroKeraApp()));
    await tester.pumpAndSettle();

    // Verify AppLogo and Navigation Tabs are present
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('მთავარი'), findsOneWidget);
    expect(find.text('მარკეტი'), findsOneWidget);
    expect(find.text('პროფილი'), findsOneWidget);

    // Verify Guest Promo Banner is shown on Home screen in Guest Mode
    expect(find.byType(GuestPromoBanner), findsOneWidget);
    expect(find.text('არ გაქვს ანგარიში?'), findsOneWidget);
  });

  testWidgets('MainNavScreen dynamically shows 4 tabs in Farmer mode', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Set role to farmer
    container.read(authStateProvider.notifier).login(
      role: UserRole.farmer,
      name: 'ლანა მახარაძე',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MainNavScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 4 tabs are present
    expect(find.text('მთავარი'), findsOneWidget);
    expect(find.text('მარკეტი'), findsOneWidget);
    expect(find.text('ჩემი ფერმა'), findsOneWidget);
    expect(find.text('პროფილი'), findsOneWidget);

    // Tap on Farmer tab
    await tester.tap(find.text('ჩემი ფერმა'));
    await tester.pumpAndSettle();

    // Verify Farmer Dashboard is active
    expect(find.text('საფერმო პანელი'), findsOneWidget);
    expect(find.text('ფერმა „ლანა მახარაძე“'), findsOneWidget);
  });
}
