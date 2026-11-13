import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/main.dart';
import 'package:agrokera/core/widgets/app_logo.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
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
}
