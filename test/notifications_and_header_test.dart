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
}

