import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Hero Identity for Guest (starts directly with avatar, no "პროფილის გვერდი" header)
    expect(find.text('სტუმარი'), findsOneWidget);
    expect(find.text('სისტემაში შესვლა / რეგისტრაცია'), findsOneWidget);
    expect(find.text('გახდი აგროკერას წევრი'), findsOneWidget);
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
}

