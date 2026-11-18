import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/main.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/widgets/app_logo.dart';
import 'package:agrokera/features/marketplace/data/models/category_model.dart';
import 'package:agrokera/features/marketplace/presentation/screens/category_products_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    expect(find.byKey(const ValueKey('nav_tab_მთავარი')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_tab_მარკეტი')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_tab_პროფილი')), findsOneWidget);
    expect(find.text('მთავარი'), findsOneWidget);

    // Verify Guest Promo Banner is shown on Home screen in Guest Mode
    expect(find.byType(GuestPromoBanner), findsOneWidget);
    expect(find.text('არ გაქვს ანგარიში?'), findsOneWidget);

    // Verify Quick Categories Bar is rendered on Home screen
    expect(find.text('სწრაფი კატეგორიები'), findsOneWidget);
    expect(find.text('ხილი'), findsWidgets);
    expect(find.text('ბოსტნეული'), findsWidgets);
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

    // Verify all 4 tabs are present by their keys
    expect(find.byKey(const ValueKey('nav_tab_მთავარი')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_tab_მარკეტი')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_tab_ფერმა')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_tab_პროფილი')), findsOneWidget);
    expect(find.text('მთავარი'), findsOneWidget);

    // Tap on Farmer tab
    await tester.tap(find.byKey(const ValueKey('nav_tab_ფერმა')));
    await tester.pumpAndSettle();

    // Verify Farmer Farm dashboard is active
    expect(find.text('ფერმა'), findsOneWidget);
    expect(find.text('ჩემი ფერმა'), findsOneWidget);
    expect(find.text('პროდუქტის მენეჯმენტი'), findsOneWidget);
  });

  testWidgets('MainNavScreen automatically switches to Home tab on logout', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(authStateProvider.notifier).login(
      role: UserRole.customer,
      name: 'გიორგი ბერიძე',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MainNavScreen(initialIndex: 2), // Profile tab
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger logout
    container.read(authStateProvider.notifier).logout();
    await tester.pumpAndSettle();

    // Verify user is transitioned to Home tab
    expect(find.byType(GuestPromoBanner), findsOneWidget);
    expect(find.text('არ გაქვს ანგარიში?'), findsOneWidget);
  });

  testWidgets(
      'CategoryProductsScreen displays empty state with emptyProducts illustration when no products match',
      (tester) async {
    final container = ProviderContainer();
    const emptyCategory = CategoryModel(
      id: 'cat_empty',
      name: 'უცნობი კატეგორია',
      productCount: 0,
      imageUrl: '',
      backgroundColor: Colors.transparent,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CategoryProductsScreen(category: emptyCategory),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('პროდუქტები ვერ მოიძებნა'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
  });
}
