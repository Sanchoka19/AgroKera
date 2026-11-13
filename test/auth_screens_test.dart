import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/auth/presentation/screens/login_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/sms_verification_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/farmer_role_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/customer_role_screen.dart';
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

  testWidgets('LoginScreen renders fields and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ავტორიზაცია'), findsOneWidget);
    expect(find.text('შესვლა'), findsOneWidget);
    expect(find.text('დაგავიწყდა პაროლი?'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('შექმენით'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('SmsVerificationScreen renders PIN boxes and countdown', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const SmsVerificationScreen(email: 'test@agrokera.ge')));
    await tester.pump();

    expect(find.text('SMS დადასტურება'), findsOneWidget);
    expect(find.text('შეიყვანეთ SMS კოდი'), findsOneWidget);
    expect(find.text('კოდი გაიგზავნა test@agrokera.ge'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('ახლიდან გაგზავნა'),
      ),
      findsOneWidget,
    );
    expect(find.text('დადასტურება'), findsOneWidget);
  });

  testWidgets('ResetPasswordScreen renders password fields and button', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const ResetPasswordScreen()));
    await tester.pumpAndSettle();

    expect(find.text('პაროლის აღდგენა'), findsOneWidget);
    expect(find.text('თქვენი ახალი პაროლი განსხვავებული უნდა იყოს ძველი პაროლისგან'), findsOneWidget);
    expect(find.text('განახლება'), findsOneWidget);
  });

  testWidgets('RoleSelectionScreen renders Farmer and Customer options', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const RoleSelectionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('აირჩიე როლი'), findsOneWidget);
    expect(find.text('მე ვარ ფერმერი'), findsOneWidget);
    expect(find.text('მოაწყვე და მართე შენი ფერმა'), findsOneWidget);
    expect(find.text('მე ვარ მომხმარებელი'), findsOneWidget);
    expect(find.text('იყიდე ეკოლოგიურად სუფთა პროდუქტები'), findsOneWidget);
  });

  testWidgets('FarmerRoleScreen renders features and register button', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const FarmerRoleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ფერმერი'), findsOneWidget);
    expect(find.text('რისი გაკეთება შეგიძლია:'), findsOneWidget);
    expect(find.text('პროდუქტების გაყიდვა'), findsOneWidget);
    expect(find.text('თქვენი სარგებელი'), findsOneWidget);
    expect(find.text('რეგისტრაცია ფერმერად'), findsOneWidget);
    expect(find.text('სხვა როლის არჩევა'), findsOneWidget);
  });

  testWidgets('CustomerRoleScreen renders benefits and register button', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const CustomerRoleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('მომხმარებელი'), findsOneWidget);
    expect(find.text('თქვენი სარგებელი'), findsOneWidget);
    expect(find.text('ონლაინ ვაჭრობა'), findsOneWidget);
    expect(find.text('რეგისტრაცია მომხმარებლად'), findsOneWidget);
    expect(find.text('სხვა როლის არჩევა'), findsOneWidget);
  });
}
