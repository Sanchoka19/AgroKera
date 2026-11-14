import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/widgets/app_confirmation_bottom_sheet.dart';

void main() {
  group('AppConfirmationBottomSheet Tests', () {
    testWidgets('showLogout renders warning UI and returns true on confirm', (tester) async {
      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmedResult = await AppConfirmationBottomSheet.showLogout(
                    context: context,
                  );
                },
                child: const Text('Open Logout Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Logout Sheet'));
      await tester.pumpAndSettle();

      // Check title and message
      expect(find.text('ანგარიშიდან გამოსვლა'), findsOneWidget);
      expect(find.textContaining('ნამდვილად გსურთ სისტემიდან გამოსვლა?'), findsOneWidget);
      expect(find.text('დარჩენა'), findsOneWidget);
      expect(find.text('გამოსვლა'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.widgetWithText(ElevatedButton, 'გამოსვლა'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isTrue);
    });

    testWidgets('returns false on cancel tap', (tester) async {
      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmedResult = await AppConfirmationBottomSheet.showClearCart(
                    context: context,
                  );
                },
                child: const Text('Open Clear Cart Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Clear Cart Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('კალათის გასუფთავება'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.widgetWithText(OutlinedButton, 'უკან'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isFalse);
    });

    testWidgets('showCompleteOrder renders positive confirmation UI', (tester) async {
      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmedResult = await AppConfirmationBottomSheet.showCompleteOrder(
                    context: context,
                    orderId: '12345',
                  );
                },
                child: const Text('Open Complete Order Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Complete Order Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('შეკვეთის დასრულება'), findsWidgets);
      expect(find.textContaining('#12345'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'დასრულება'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isTrue);
    });
  });
}
