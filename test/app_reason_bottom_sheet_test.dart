import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/widgets/app_reason_bottom_sheet.dart';

void main() {
  group('AppReasonBottomSheet Tests', () {
    testWidgets('renders all template reasons and confirms with selected reason', (tester) async {
      String? returnedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    returnedReason = await AppReasonBottomSheet.show(
                      context: context,
                      title: 'შეკვეთის გაუქმება',
                      subtitle: 'შეკვეთა #12345',
                      confirmButtonText: 'გაუქმება',
                      reasons: AppReasonBottomSheet.defaultOrderCancellationReasons,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('შეკვეთის გაუქმება'), findsOneWidget);
      expect(find.text('შეკვეთა #12345'), findsOneWidget);

      // Verify default template reasons exist
      expect(find.text('მარაგი ამოიწურა'), findsOneWidget);
      expect(find.text('ტრანსპორტირება ვერ ხორციელდება'), findsOneWidget);
      expect(find.text('უამინდობა / ტექნიკური შეფერხება'), findsOneWidget);
      expect(find.text('დამკვეთის მოთხოვნით'), findsOneWidget);

      // Select 'ტრანსპორტირება ვერ ხორციელდება'
      await tester.tap(find.text('ტრანსპორტირება ვერ ხორციელდება'));
      await tester.pumpAndSettle();

      // Tap confirm button (the ElevatedButton with 'გაუქმება')
      await tester.tap(find.widgetWithText(ElevatedButton, 'გაუქმება'));
      await tester.pumpAndSettle();

      // Modal closed and returned selected reason
      expect(returnedReason, equals('ტრანსპორტირება ვერ ხორციელდება'));
    });

    testWidgets('custom reason with comment returns combined reason string', (tester) async {
      String? returnedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    returnedReason = await AppReasonBottomSheet.show(
                      context: context,
                      title: 'გაუქმების მოთხოვნა',
                      confirmButtonText: 'გაგზავნა',
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Enter comment into text field
      await tester.enterText(find.byType(TextField), 'პროდუქტი გაფუჭდა');
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.widgetWithText(ElevatedButton, 'გაგზავნა'));
      await tester.pumpAndSettle();

      // Default reason + custom note
      expect(returnedReason, equals('მარაგი ამოიწურა (პროდუქტი გაფუჭდა)'));
    });
  });
}
