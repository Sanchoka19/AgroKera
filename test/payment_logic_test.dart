import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/cart_checkout/domain/models/payment_method_model.dart';
import 'package:agrokera/features/cart_checkout/presentation/providers/payment_provider.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/payment/escrow_bank_details_widget.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/payment/order_placed_dialog.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/payment/payment_method_card.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/payment/payment_selection_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Logic & Business Rules Unit Tests', () {
    test('Initial state defaults to AgroKera Escrow Bank Transfer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(paymentProvider);
      expect(state.selectedMethod, equals(PaymentMethodType.bankTransfer));
      expect(state.escrowDetails.iban, equals('GE29TB7553608011000018'));
      expect(state.escrowDetails.identificationCode, equals('405123456'));
      expect(state.savedCard?.lastFour, equals('4242'));
    });

    test('Can switch payment method to Cash and back to BankTransfer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(paymentProvider.notifier).selectMethod(PaymentMethodType.cash);
      expect(container.read(paymentProvider).selectedMethod, equals(PaymentMethodType.cash));

      container.read(paymentProvider.notifier).selectMethod(PaymentMethodType.bankTransfer);
      expect(container.read(paymentProvider).selectedMethod, equals(PaymentMethodType.bankTransfer));
    });

    test('Escrow model guarantees frozen funds description and safety badge', () {
      expect(PaymentMethodType.bankTransfer.label, equals('საბანკო გადარიცხვა'));
      expect(PaymentMethodType.bankTransfer.badgeText, equals('Escrow დაცული'));
      expect(PaymentMethodType.cash.badgeText, equals('ადგილზე'));
    });
  });

  group('Payment UI Widget Tests', () {
    testWidgets('PaymentMethodCard renders escrow wire transfer info by default', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentMethodCard(grandTotal: 85.0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('გადახდის მეთოდი'), findsOneWidget);
      expect(find.text('შეცვლა'), findsOneWidget);
      expect(find.text('საბანკო გადარიცხვა'), findsOneWidget);
      expect(find.text('AgroKera Escrow დაცვა'), findsOneWidget);
      expect(find.text('GE29TB7553608011000018'), findsOneWidget);
    });

    testWidgets('PaymentSelectionSheet opens and switches method to Cash', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => PaymentSelectionSheet.show(context),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('საბანკო გადარიცხვა'), findsWidgets);
      expect(find.text('ნაღდი ფულით გადახდა'), findsOneWidget);

      // Tap Cash option
      await tester.tap(find.text('ნაღდი ფულით გადახდა'));
      await tester.pumpAndSettle();

      // Tap confirm button 'არჩევა'
      await tester.tap(find.text('არჩევა'));
      await tester.pumpAndSettle();

      expect(container.read(paymentProvider).selectedMethod, equals(PaymentMethodType.cash));
    });

    testWidgets('EscrowBankDetailsWidget renders bank details with one-tap copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EscrowBankDetailsWidget(
              escrow: AgroKeraEscrowDetails.standard,
              orderReference: 'AK-38195',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GE29TB7553608011000018'), findsOneWidget);
      expect(find.text('კოპირება'), findsOneWidget);
      expect(find.text('მიმღები: შპს "აგროკერა" (AgroKera LLC)'), findsOneWidget);
      expect(find.text('ს/კ: 405123456'), findsOneWidget);
      expect(find.text('დანიშნულება: AK-38195'), findsOneWidget);
    });

    testWidgets('OrderPlacedDialog adapts content based on payment method', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderPlacedDialog(
              orderId: '49201',
              totalAmount: 120.0,
              paymentMethod: PaymentMethodType.cash,
              escrowDetails: AgroKeraEscrowDetails.standard,
              isPickup: false,
              location: 'თელავი, კახეთი',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('შეკვეთის მოთხოვნა გაიგზავნა!'), findsOneWidget);
      expect(find.text('შეკვეთის კოდი: AK-49201'), findsOneWidget);
      expect(find.textContaining('თანხას (120 ₾) გადაიხდით ნაღდი ფულით კურიერთან ჩაბარებისას.'), findsOneWidget);

      await tester.tap(find.text('მთავარზე დაბრუნება'));
      expect(dismissed, isTrue);
    });
  });
}

