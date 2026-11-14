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

  testWidgets('Authenticated Profile renders Hero Avatar, KPI card, and logout', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(authStateProvider.notifier).login(
          name: 'საბა ევგენიძე',
          email: 'sabaevgenidze0919@gmail.com',
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
    expect(find.text('საბა ევგენიძე'), findsOneWidget);
    expect(find.text('sabaevgenidze0919@gmail.com'), findsOneWidget);
    expect(find.text('თვიური რეიტინგი და KPI'), findsOneWidget);
    expect(find.text('გამოსვლა'), findsOneWidget);
  });
}

