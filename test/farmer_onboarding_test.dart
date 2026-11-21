import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/screens/farmer_onboarding_screen.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/providers/farmer_onboarding_provider.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/onboarding_shared_widgets.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/onboarding_steps/step5_sms_verification_widget.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  Widget wrapWithScaffold(Widget child, [ProviderContainer? container]) {
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: child,
        ),
      );
    }
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('FarmerOnboardingScreen renders step 1 and navigates through steps', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrapWithScaffold(const FarmerOnboardingScreen(), container));
    await tester.pumpAndSettle();

    // Step 1: Farm Info
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('ფერმის ინფორმაცია'), findsOneWidget);
    expect(find.text('მისამართი'), findsOneWidget);
    expect(find.text('შემდეგი'), findsOneWidget);

    // Blocked if required fields are empty
    await tester.tap(find.text('შემდეგი'));
    await tester.pump();
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('2/4'), findsNothing);

    // Populate required fields for Step 1
    container.read(farmerOnboardingProvider.notifier).setFarmName('მწვანე ველი');
    container.read(farmerOnboardingProvider.notifier).setFarmPhoto(
      path: 'assets/sample.jpg',
      name: 'Sample Farm Cover',
    );
    await tester.pumpAndSettle();

    // Tap Next -> Step 2
    await tester.tap(find.text('შემდეგი'));
    await tester.pumpAndSettle();

    // Step 2: Choose Status
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('ფიზიკური პირი'), findsOneWidget);
    expect(find.text('ინდ. მეწარმე'), findsOneWidget);
    expect(find.text('შპს'), findsOneWidget);

    // Tap Next -> Step 3: Delivery Options
    await tester.tap(find.text('შემდეგი'));
    await tester.pumpAndSettle();

    // Step 3: Delivery Options
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('მიწოდების პირობები'), findsOneWidget);
    expect(find.text('თვითგატანა მეურნეობიდან'), findsOneWidget);
    expect(find.text('საბაზისო პირობა • მუდმივად აქტიური'), findsOneWidget);
    expect(find.text('ჩემი მიტანის სერვისი (რეისები)'), findsOneWidget);

    // Tap self-pickup switch and verify it cannot be disabled
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text('თვითგატანა მეურნეობიდან არის საბაზისო პირობა და მისი გათიშვა შეუძლებელია'), findsOneWidget);

    // Turn on farmer scheduled delivery
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    // Verify fee pills: 5 ₾, 7 ₾, 10 ₾, 15 ₾ and "სხვა"
    await tester.ensureVisible(find.text('სხვა'));
    expect(find.text('5 ₾'), findsOneWidget);
    expect(find.text('7 ₾'), findsOneWidget);
    expect(find.text('10 ₾'), findsOneWidget);
    expect(find.text('15 ₾'), findsOneWidget);
    expect(find.text('სხვა'), findsOneWidget);

    // Tap "სხვა" to open custom fee input
    await tester.tap(find.text('სხვა'));
    await tester.pumpAndSettle();
    expect(find.text('საკუთარი საფასური:'), findsOneWidget);

    // Enter custom price: 18 ₾
    await tester.enterText(find.byType(TextField).last, '18');
    await tester.pumpAndSettle();
    expect(find.text('18 ₾'), findsOneWidget);

    // Tap Next -> Step 4
    await tester.ensureVisible(find.text('შემდეგი'));
    await tester.tap(find.text('შემდეგი'));
    await tester.pumpAndSettle();

    // Step 4: Review & Terms
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('დეტალები'), findsOneWidget);
    expect(find.text('მისამართი:'), findsOneWidget);
    expect(find.text('წესები და პირობები'), findsOneWidget);
    expect(find.text('დადასტურება'), findsOneWidget);

    // Verify next is disabled/blocked while checkboxes are not checked
    await tester.tap(find.text('დადასტურება'));
    await tester.pump();
    expect(find.text('4/4'), findsOneWidget);

    // Check both terms and conditions checkboxes
    await tester.ensureVisible(find.byType(OnboardingCustomCheckbox).first);
    await tester.tap(find.byType(OnboardingCustomCheckbox).first);
    await tester.ensureVisible(find.byType(OnboardingCustomCheckbox).last);
    await tester.tap(find.byType(OnboardingCustomCheckbox).last);
    await tester.pumpAndSettle();

    // Tap Confirm -> completes onboarding directly
    await tester.tap(find.text('დადასტურება'));
    await tester.pumpAndSettle();

    expect(find.text('4/4'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
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

    expect(find.text('მონიშნეთ რუკაზე'), findsOneWidget);
    expect(find.text('Leaflet | © OpenStreetMap contributors'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('შეეხეთ რუკას მოსანიშნად'), findsOneWidget);
  });

  testWidgets('FarmerMapWidget opens full address bottom sheet on tapping address pill', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithScaffold(
        const FarmerMapWidget(
          locationText: 'კახეთი, გურჯაანის მუნიციპალიტეტი, სოფელი ვაჩნაძიანი',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on address indicator chip
    await tester.tap(find.text('მონიშნეთ რუკაზე'));
    await tester.pumpAndSettle();

    // Verify modal bottom sheet opens with full address details
    expect(find.text('სრული მისამართი'), findsOneWidget);
    expect(find.text('კახეთი, გურჯაანის მუნიციპალიტეტი, სოფელი ვაჩნაძიანი'), findsOneWidget);
    expect(find.text('კოპირება'), findsOneWidget);
    expect(find.text('გასაგებია'), findsOneWidget);

    // Close bottom sheet
    await tester.tap(find.text('გასაგებია'));
    await tester.pumpAndSettle();

    expect(find.text('სრული მისამართი'), findsNothing);
  });

  testWidgets('GeorgianGeoLookup dynamically resolves addresses accurately', (WidgetTester tester) async {
    final gurjaani = GeorgianGeoLookup.resolveInstantAddress(const LatLng(41.7456, 45.7983));
    expect(gurjaani, contains('გურჯაანი'));

    final batumi = GeorgianGeoLookup.resolveInstantAddress(const LatLng(41.6168, 41.6367));
    expect(batumi, contains('ბათუმი'));

    final akhalsheni = GeorgianGeoLookup.resolveInstantAddress(const LatLng(41.6033, 41.6917));
    expect(akhalsheni, contains('ახალშენი'));
  });

  testWidgets('FarmerOnboarding allows in-place email change and controller persistence', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pinControllers = List.generate(5, (_) => TextEditingController());
    final pinFocusNodes = List.generate(5, (_) => FocusNode());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Step5SmsVerificationWidget(
              pinControllers: pinControllers,
              pinFocusNodes: pinFocusNodes,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('შეიყვანეთ SMS კოდი'), findsOneWidget);

    // Tap email edit button
    await tester.tap(find.text('შეცვლა'));
    await tester.pump(const Duration(milliseconds: 300));

    // Edit email bottom sheet is open
    expect(find.text('ელ-ფოსტის შეცვლა'), findsOneWidget);
    expect(find.text('შენახვა და კოდის გაგზავნა'), findsOneWidget);

    // Enter a new email
    await tester.enterText(find.byType(TextFormField), 'newfarmer@agrokera.ge');
    await tester.pump(const Duration(milliseconds: 300));

    // Tap save
    await tester.tap(find.text('შენახვა და კოდის გაგზავნა'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Bottom sheet closed and verification email updated
    expect(find.text('newfarmer@agrokera.ge'), findsOneWidget);
    expect(container.read(farmerOnboardingProvider.notifier).resolveVerificationEmail(), 'newfarmer@agrokera.ge');

    container.read(farmerOnboardingProvider.notifier).cancelTimer();

    for (final c in pinControllers) {
      c.dispose();
    }
    for (final f in pinFocusNodes) {
      f.dispose();
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

