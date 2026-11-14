import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/profile/presentation/screens/guest_profile_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  Widget wrapWithScaffold(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('GuestProfileScreen renders grouped sections and headers', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const GuestProfileScreen()));
    await tester.pumpAndSettle();

    // Guest Mode: Official illustration banner from previous version
    expect(find.text('არ გაქვს ანგარიში?'), findsOneWidget);
    expect(find.text('ავტორიზაცია'), findsOneWidget);
    expect(find.text('რეგისტრაცია'), findsOneWidget);
    expect(find.text('პროფილის გვერდი'), findsNothing);

    // Section 1 Header & Items (matching mockup)
    expect(find.text('ინსტრუმენტები და სერვისები'), findsOneWidget);
    expect(find.text('ჩემი შეკვეთები'), findsOneWidget);
    expect(find.text('ჩემი მისამართი'), findsOneWidget);
    expect(find.text('საბანკო ანგარიშები'), findsOneWidget);

    // Section 2: პარამეტრები
    expect(find.text('პარამეტრები'), findsOneWidget);
    expect(find.text('აპლიკაციის ენა'), findsOneWidget);
    expect(find.text('შეტყობინებები'), findsOneWidget);

    // Section 3: დახმარება და მხარდაჭერა
    expect(find.text('დახმარება და მხარდაჭერა'), findsOneWidget);
    expect(find.text('დახმარების ცენტრი'), findsOneWidget);

    // Footer Version
    expect(find.text('აგროკერა • ვერსია 1.0.0'), findsOneWidget);
  });

  testWidgets('Authenticated Customer Profile renders Hero Avatar, NO KPI card, and logout', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'გიორგი ბერიძე',
          email: 'user@example.ge',
          role: UserRole.customer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Authenticated Hero Identity
    expect(find.text('გიორგი ბერიძე'), findsOneWidget);
    expect(find.text('user@example.ge'), findsOneWidget);
    // Regular customer does NOT need KPI card
    expect(find.text('თვიური რეიტინგი და KPI'), findsNothing);
    expect(find.text('საფერმო მაჩვენებლები და KPI'), findsNothing);
    expect(find.text('გამოსვლა'), findsOneWidget);
  });

  testWidgets('Authenticated Farmer Profile renders Hero Avatar, KPI card, and verified badge', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'რევაზ ბერიძე',
          email: 'revaz@farm.ge',
          role: UserRole.farmer,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GuestProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Farmer Profile
    expect(find.text('რევაზ ბერიძე'), findsOneWidget);
    expect(find.text('საფერმო მაჩვენებლები და KPI'), findsOneWidget);
    expect(find.text('ვერიფიცირებული'), findsOneWidget);
    expect(find.text('გამოსვლა'), findsOneWidget);
  });
}

