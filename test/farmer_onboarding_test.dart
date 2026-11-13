import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/screens/farmer_onboarding_screen.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
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

  testWidgets('FarmerOnboardingScreen renders step 1 and navigates through steps', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const FarmerOnboardingScreen()));
    await tester.pumpAndSettle();

    // Step 1: Farm Info
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('ფერმის ინფორმაცია'), findsOneWidget);
    expect(find.text('მისამართი'), findsOneWidget);
    expect(find.text('შემდეგი'), findsOneWidget);

    // Tap Next -> Step 2
    await tester.tap(find.text('შემდეგი'));
    await tester.pumpAndSettle();

    // Step 2: Choose Status
    expect(find.text('2/5'), findsOneWidget);
    expect(find.text('ფიზიკური პირი'), findsOneWidget);
    expect(find.text('ინდ. მეწარმე'), findsOneWidget);
    expect(find.text('შპს'), findsOneWidget);

    // Tap Next -> Step 3
    await tester.tap(find.text('შემდეგი'));
    await tester.pumpAndSettle();

    // Step 3: Legal & Bank
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('საბანკო ანგარიში'), findsOneWidget);

    // Tap Next -> Step 4
    await tester.tap(find.text('შემდეგი'));
    await tester.pumpAndSettle();

    // Step 4: Review & Terms
    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('დეტალები'), findsOneWidget);
    expect(find.text('წესები და პირობები'), findsOneWidget);

    // Tap Next -> Step 5
    await tester.tap(find.text('შემდეგი'));
    await tester.pump();

    // Step 5: SMS OTP
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('შეიყვანეთ SMS კოდი'), findsOneWidget);
    expect(find.text('დადასტურება'), findsOneWidget);
  });

  testWidgets('FarmerMapWidget renders OpenStreetMap tiles and attribution', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithScaffold(
        const FarmerMapWidget(
          locationText: 'კახეთი, გურჯაანი',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('მიმდინარე მისამართი'), findsOneWidget);
    expect(find.text('Leaflet | © OpenStreetMap contributors'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}

