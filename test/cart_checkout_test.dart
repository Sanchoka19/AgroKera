import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import 'package:agrokera/features/cart_checkout/presentation/providers/cart_provider.dart';
import 'package:agrokera/features/cart_checkout/presentation/screens/cart_screen.dart';
import 'package:agrokera/features/cart_checkout/presentation/screens/checkout_screen.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/fee_breakdown_sheet.dart';

void main() {
  group('Cart Provider Unit Tests', () {
    test('initial state has sample items', () {
      final container = ProviderContainer();
      final items = container.read(cartProvider);
      expect(items.length, 2);
      expect(items.first.title, 'ვარდისფერი პომიდორი');
      expect(items.subtotal, greaterThan(0));
    });

    test('can clear cart, increment, decrement and add items', () {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);

      notifier.addItem(
        const CartItemModel(
          id: 'test_1',
          title: 'ტესტ პომიდორი',
          packageText: '1კგ',
          farmerName: 'მწვანე ველი',
          pricePerUnit: 5.0,
          quantity: 2,
          imageUrl: '',
          weightKg: 1.0,
        ),
      );

      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.quantity, 2);
      expect(container.read(cartProvider).subtotal, 10.0);

      notifier.increment('test_1');
      expect(container.read(cartProvider).first.quantity, 3);
      expect(container.read(cartProvider).subtotal, 15.0);

      notifier.decrement('test_1');
      expect(container.read(cartProvider).first.quantity, 2);
    });
  });

  group('Cart Screen Widget Tests', () {
    testWidgets('renders populated cart with stepper and totals', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('კალათი'), findsOneWidget);
      expect(find.text('ვარდისფერი პომიდორი'), findsOneWidget);
      expect(find.text('ადიგენის კარტოფილი'), findsOneWidget);
    });

    testWidgets('renders empty cart state when cart has no items', (tester) async {
      final container = ProviderContainer();
      container.read(cartProvider.notifier).clearCart();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ჩემი კალათი'), findsOneWidget);
      expect(find.text('შენი კალათი ცარიელია!'), findsOneWidget);
      expect(find.text('კალათის შევსება'), findsOneWidget);
    });

    testWidgets('renders checkout screen with order summary', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('გადახდა'), findsOneWidget);
      expect(find.text('მიტანის მისამართი'), findsOneWidget);
      expect(find.text('შეკვეთის შეჯამება'), findsOneWidget);
      expect(find.text('მოსაკრებელი'), findsOneWidget);
    });

    testWidgets('renders fee breakdown sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeeBreakdownSheet(
              currentWeight: 26.0,
              currentSubtotal: 50.0,
              type: FeeBreakdownType.heavyWeight,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('რა განსაზღვრავს ჩვენს'), findsOneWidget);
      expect(find.text('მიტანის საფასური კარამდე'), findsOneWidget);
      expect(find.text('გასაგებია'), findsOneWidget);
    });
  });
}

