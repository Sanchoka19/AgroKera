import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/widgets/product_quick_add_bottom_sheet.dart';
import 'package:agrokera/core/widgets/product_cart_helper.dart';
import 'package:agrokera/core/widgets/draggable_floating_cart.dart';
import 'package:agrokera/features/cart_checkout/presentation/providers/cart_provider.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/presentation/screens/category_products_screen.dart';
import 'package:agrokera/core/constants/app_categories.dart';

void main() {
  const minOrderProduct = ProductModel(
    id: 'prod_min_5',
    title: 'კარტოფილი',
    category: 'ბოსტნეული',
    farmerId: 'farmer_1',
    farmerName: 'სოფლის მეურნეობა',
    price: 3.0,
    unit: 'კგ',
    imageUrl: 'assets/images/potato.png',
    description: 'ახალი კარტოფილი',
    minOrderQuantity: 5.0,
    stockQuantity: 100.0,
  );

  const singleUnitProduct = ProductModel(
    id: 'prod_single_1',
    title: 'მწვანილი',
    category: 'ბოსტნეული',
    farmerId: 'farmer_1',
    farmerName: 'სოფლის მეურნეობა',
    price: 2.0,
    unit: 'კონა',
    imageUrl: 'assets/images/greens.png',
    description: 'ახალი მწვანილი',
    minOrderQuantity: 1.0,
    stockQuantity: 50.0,
  );

  testWidgets(
      'ProductQuickAddBottomSheet displays minimum order notice and enforces bounds',
      (tester) async {
    int? confirmedQuantity;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ProductQuickAddBottomSheet.show(
                  context: context,
                  product: minOrderProduct,
                  onConfirm: (qty) => confirmedQuantity = qty,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify minimum order notice is displayed
    expect(find.text('კარტოფილი'), findsOneWidget);
    expect(
      find.text('ფერმერის მიერ განსაზღვრული მინიმალური შეკვეთაა 5 კგ.'),
      findsOneWidget,
    );
    expect(find.text('5'), findsOneWidget);

    // Try to decrement below 5 -> should stay at 5
    await tester.tap(find.byIcon(LucideIcons.minus));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    // Increment to 6
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();
    expect(find.text('6'), findsOneWidget);

    // Directly enter large quantity in TextField
    await tester.enterText(find.byType(TextField), '25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('25'), findsOneWidget);

    // Confirm adding to cart
    await tester.tap(find.textContaining('კალათაში დამატება'));
    await tester.pumpAndSettle();

    expect(confirmedQuantity, 25);
  });

  testWidgets('ProductCartHelper directly adds when minOrderQuantity is 1',
      (tester) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () {
                  ProductCartHelper.handleAddToCart(
                    context: context,
                    ref: ref,
                    product: singleUnitProduct,
                  );
                },
                child: const Text('Add Single'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to add
    await tester.tap(find.text('Add Single'));
    await tester.pumpAndSettle();

    // Verify item was directly added to cart with quantity 1
    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart.first.id, 'prod_single_1');
    expect(cart.first.quantity, 1);
  });

  testWidgets('CategoryProductsScreen displays DraggableFloatingCart',
      (tester) async {
    final container = ProviderContainer();

    final category = AppCategories.categories.first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CategoryProductsScreen(category: category),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify DraggableFloatingCart is present in widget tree
    expect(find.byType(DraggableFloatingCart), findsOneWidget);
  });
}
