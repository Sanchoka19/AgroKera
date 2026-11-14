import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/widgets/app_header.dart';
import 'package:agrokera/core/widgets/app_search_bar.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:agrokera/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:agrokera/features/marketplace/presentation/screens/categories_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/global_search_dialog.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  Widget wrapWithScaffold(Widget child, [ProviderContainer? container]) {
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }
    return ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('AppHeader renders title and notification bell with unread badge',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrapWithScaffold(
        const AppHeader(
          title: 'აგრო მარკეტი',
          showNotificationBell: true,
          showCart: true,
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    // Verify title is rendered
    expect(find.text('აგრო მარკეტი'), findsOneWidget);

    // Verify bell and cart icons are present
    expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    expect(find.byIcon(LucideIcons.shoppingCart), findsOneWidget);

    // Initial unread notifications count is 2 (from sample data)
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('AppHeader opens NotificationsScreen on tapping notification bell',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrapWithScaffold(
        const AppHeader(
          title: 'ჩემი კაბინეტი',
          showNotificationBell: true,
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    // Tap notification bell
    await tester.tap(find.byIcon(LucideIcons.bell));
    await tester.pumpAndSettle();

    // Verify NotificationsScreen is displayed
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('შეტყობინებები'), findsOneWidget);
    expect(find.text('ყველას წაკითხვა'), findsOneWidget);
  });

  testWidgets('NotificationsScreen filters by category and marks as read',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial filter chips
    expect(find.text('ყველა'), findsOneWidget);
    expect(find.text('შეკვეთები'), findsOneWidget);
    expect(find.text('აქციები'), findsOneWidget);
    expect(find.text('სისტემური'), findsOneWidget);

    // Filter to 'აქციები'
    await tester.tap(find.text('აქციები'));
    await tester.pumpAndSettle();

    expect(find.text('სეზონური ფასდაკლება 20%'), findsOneWidget);
    expect(find.text('შეკვეთა #12345 მიღებულია'), findsNothing);

    // Switch back to 'ყველა' and tap 'ყველას წაკითხვა'
    await tester.tap(find.text('ყველა'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ყველას წაკითხვა'));
    await tester.pumpAndSettle();

    // Unread count should now be 0, button disappears
    expect(find.text('ყველას წაკითხვა'), findsNothing);
    expect(container.read(unreadNotificationsCountProvider), equals(0));
  });

  testWidgets('AppSearchBar in tap mode renders hintText and responds to tap',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      wrapWithScaffold(
        AppSearchBar(
          hintText: 'მოძებნე პროდუქტი...',
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('მოძებნე პროდუქტი...'), findsOneWidget);
    expect(find.byIcon(LucideIcons.search), findsOneWidget);

    await tester.tap(find.byType(AppSearchBar));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('AppToast displays floating pill with icon and action callback',
      (WidgetTester tester) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppToast.success(
                  context,
                  'ბულგარული წიწაკა დამატებულია კალათაში!',
                  actionLabel: 'კალათა',
                  onAction: () => actionTapped = true,
                );
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300));

    // Verify toast contents
    expect(find.text('ბულგარული წიწაკა დამატებულია კალათაში!'), findsOneWidget);
    expect(find.text('კალათა'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    // Tap action
    await tester.tap(find.text('კალათა'));
    await tester.pumpAndSettle();

    expect(actionTapped, isTrue);
  });

  testWidgets('AppToast handles error, warning, info and dismisses cleanly',
      (WidgetTester tester) async {
    BuildContext? testContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Error toast
    AppToast.error(testContext!, 'შეცდომა დაფიქსირდა');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('შეცდომა დაფიქსირდა'), findsOneWidget);
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    // 2. Info toast replaces previous
    AppToast.info(testContext!, 'ინფორმაცია განახლდა');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('შეცდომა დაფიქსირდა'), findsNothing);
    expect(find.text('ინფორმაცია განახლდა'), findsOneWidget);
    expect(find.byIcon(LucideIcons.info), findsOneWidget);

    // 3. Manual dismiss
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('ინფორმაცია განახლდა'), findsNothing);
  });

  testWidgets('CategoriesScreen renders bento cards and filters by search',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CategoriesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subheader
    expect(find.text('აგრო მარკეტი'), findsOneWidget);
    expect(find.text('100% ორგანული'), findsOneWidget);
    expect(find.text('ხილი'), findsOneWidget);
    expect(find.text('ციტრუსი'), findsOneWidget);

    // Search for 'ბოსტ'
    await tester.enterText(find.byType(TextField), 'ბოსტ');
    await tester.pumpAndSettle();

    expect(find.text('ბოსტნეული'), findsOneWidget);
    expect(find.text('ხილი'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.text('ხილი'), findsOneWidget);
    expect(find.text('ციტრუსი'), findsOneWidget);
  });

  testWidgets(
      'GlobalSearchDialog renders matching product tile without overflow on mobile viewport',
      (WidgetTester tester) async {
    // Set viewport to mobile size (390 x 778) as seen in user screenshot
    tester.view.physicalSize = const Size(390, 778);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => GlobalSearchDialog.show(context),
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Search Dialog
    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();

    expect(find.text('დახურვა'), findsOneWidget);

    // Search for "პომიდორ" (exact query from screenshot)
    await tester.enterText(find.byType(TextField), 'პომიდორ');
    await tester.pumpAndSettle();

    // Verify search results
    expect(find.text('პროდუქტები (1)'), findsOneWidget);
    expect(find.text('პომიდორი'), findsOneWidget);
    expect(find.textContaining('გიორგის ფერმა'), findsOneWidget);

    // Ensure no overflow exception occurred
    expect(tester.takeException(), isNull);

    // Close Dialog
    await tester.tap(find.text('დახურვა'));
    await tester.pumpAndSettle();

    expect(find.text('დახურვა'), findsNothing);
  });
}

