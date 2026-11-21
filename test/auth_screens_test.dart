import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/auth/presentation/screens/login_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/register_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/sms_verification_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/farmer_role_screen.dart';
import 'package:agrokera/features/auth/presentation/screens/customer_role_screen.dart';
import 'package:agrokera/features/auth/presentation/widgets/forgot_password_sheet.dart';
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

    expect(find.text('სისტემაში შესვლა'), findsWidgets);
    expect(find.text('დაგავიწყდათ პაროლი?'), findsOneWidget);
    expect(find.text('Google-ით შესვლა'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('რეგისტრაცია'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ForgotPasswordSheet renders email input and submit button', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const ForgotPasswordSheet(initialEmail: 'test@agrokera.ge')));
    await tester.pumpAndSettle();

    expect(find.text('პაროლის აღდგენა'), findsOneWidget);
    expect(find.text('კოდის გაგზავნა'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders registration inputs and CTA', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('რეგისტრაცია'), findsWidgets);
    expect(find.text('Google-ით რეგისტრაცია'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('შესვლა'),
      ),
      findsOneWidget,
    );
    expect(find.text('პაროლი'), findsWidgets);
    expect(find.text('ტელეფონის ნომერი'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('RegisterScreen validates password minimum length', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithScaffold(const RegisterScreen()));
    await tester.pumpAndSettle();

    // Enter name, email, phone, and too short password (<6 chars)
    await tester.enterText(find.byType(TextField).at(0), 'გიორგი ბერიძე');
    await tester.enterText(find.byType(TextField).at(1), 'giorgi@agrokera.ge');
    await tester.enterText(find.byType(TextField).at(2), '599123456');
    await tester.enterText(find.byType(TextField).at(3), '12345');
    await tester.pumpAndSettle();

    // Tap register button
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'რეგისტრაცია'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'რეგისტრაცია'));
    await tester.pump();

    // Verify error toast
    expect(find.text('პაროლი უნდა შედგებოდეს მინიმუმ 6 სიმბოლოსგან'), findsOneWidget);
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

    // Verify tapping on the OTP input focuses the TextField and accepts digits
    final otpTextField = find.byType(TextField);
    expect(otpTextField, findsOneWidget);
    await tester.tap(otpTextField);
    await tester.pump();

    await tester.enterText(otpTextField, '123');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
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
