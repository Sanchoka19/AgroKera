import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/auth/auth_state_provider.dart';
import '../../features/cart_checkout/presentation/providers/cart_provider.dart';
import '../../features/marketplace/data/models/product_model.dart';
import '../../features/marketplace/presentation/screens/product_details_screen.dart';
import 'app_confirmation_bottom_sheet.dart';
import 'app_toast.dart';
import 'draggable_floating_cart.dart';
import 'fly_to_cart_animator.dart';
import 'product_quick_add_bottom_sheet.dart';

/// Centralized helper for handling "Add to Cart" and "Quick Add" actions
/// uniformly across all screens (HomeScreen, CategoryProductsScreen, FavoritesScreen, etc.).
class ProductCartHelper {
  const ProductCartHelper._();

  /// Handles adding a product from a product card with Smart Quick-Add logic:
  /// - If the user owns the product: shows error.
  /// - If `product.minOrderQuantity > 1`: shows `ProductQuickAddBottomSheet` so
  ///   the user explicitly selects and confirms the minimum order quantity.
  /// - If `product.minOrderQuantity <= 1`: adds 1 item immediately to cart.
  /// - Handles single-farmer conflicts via `AppConfirmationBottomSheet.showDifferentFarmerCart`.
  /// - Plays the parabolic fly-to-cart animation if a `floatingCartKey` and `buttonContext` are available.
  static Future<void> handleAddToCart({
    required BuildContext context,
    required WidgetRef ref,
    required ProductModel product,
    GlobalKey<DraggableFloatingCartState>? floatingCartKey,
    BuildContext? buttonContext,
  }) async {
    final authState = ref.read(authStateProvider);
    if (authState.isOwnerOfProduct(product)) {
      AppToast.error(context, 'საკუთარი პროდუქტის დამატება შეუძლებელია');
      return;
    }

    if (!product.isAvailable || product.stockQuantity <= 0) {
      AppToast.info(context, 'მარაგში მეტი აღარ არის');
      return;
    }

    final minLimit = product.minOrderQuantity.toInt().clamp(1, 99999);

    if (minLimit > 1) {
      await ProductQuickAddBottomSheet.show(
        context: context,
        product: product,
        onConfirm: (selectedQty) {
          _executeAddToCart(
            context: context,
            ref: ref,
            product: product,
            quantity: selectedQty,
            floatingCartKey: floatingCartKey,
            buttonContext: buttonContext,
          );
        },
        onOpenDetails: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
      );
    } else {
      _executeAddToCart(
        context: context,
        ref: ref,
        product: product,
        quantity: 1,
        floatingCartKey: floatingCartKey,
        buttonContext: buttonContext,
      );
    }
  }

  static void _executeAddToCart({
    required BuildContext context,
    required WidgetRef ref,
    required ProductModel product,
    required int quantity,
    GlobalKey<DraggableFloatingCartState>? floatingCartKey,
    BuildContext? buttonContext,
  }) {
    final result =
        ref.read(cartProvider.notifier).addProduct(product, quantity);
    _handleResult(
      context: context,
      ref: ref,
      result: result,
      product: product,
      quantity: quantity,
      floatingCartKey: floatingCartKey,
      buttonContext: buttonContext,
    );
  }

  static void _handleResult({
    required BuildContext context,
    required WidgetRef ref,
    required AddToCartResult result,
    required ProductModel product,
    required int quantity,
    GlobalKey<DraggableFloatingCartState>? floatingCartKey,
    BuildContext? buttonContext,
  }) {
    switch (result) {
      case AddToCartOwnerForbidden():
        AppToast.error(context, 'საკუთარი პროდუქტის დამატება შეუძლებელია');
      case AddToCartOutOfStock():
        AppToast.info(context, 'მარაგში მეტი აღარ არის');
      case AddToCartAlreadyMax(:final maxStock):
        AppToast.info(
          context,
          'ეს პროდუქტი უკვე მაქსიმალური რაოდენობით ($maxStock ${product.unit}) გაქვთ კალათაში',
        );
      case AddToCartDifferentFarmer(
          :final currentFarmerName,
          :final newFarmerName
        ):
        _handleDifferentFarmer(
          context: context,
          ref: ref,
          product: product,
          quantity: quantity,
          currentFarmerName: currentFarmerName,
          newFarmerName: newFarmerName,
          floatingCartKey: floatingCartKey,
          buttonContext: buttonContext,
        );
      case AddToCartSuccess(
          :final isCapped,
          :final addedQuantity,
          :final maxStock,
          :final minOrderAdjusted,
          :final hasBulkUpsell,
          :final remainingForBulkDiscount,
          :final bulkDiscountPercent,
          :final bulkDiscountApplied,
        ):
        if (minOrderAdjusted) {
          AppToast.info(
            context,
            'მინიმალური შეკვეთაა ${product.minOrderDisplay}. კალათაში დაემატა მინიმალური რაოდენობა.',
            icon: LucideIcons.info,
          );
        } else if (isCapped) {
          AppToast.info(
            context,
            'მარაგის ლიმიტის გამო დაემატა $addedQuantity ${product.unit} (სულ კალათაში: $maxStock ${product.unit})',
            icon: LucideIcons.alertCircle,
          );
        } else if (hasBulkUpsell) {
          AppToast.info(
            context,
            'დაამატეთ კიდევ $remainingForBulkDiscount ${product.unit} და მიიღეთ $bulkDiscountPercent%-იანი საბითუმო ფასდაკლება!',
            icon: LucideIcons.flame,
          );
        } else if (bulkDiscountApplied) {
          AppToast.success(
            context,
            'გააქტიურდა $bulkDiscountPercent%-იანი საბითუმო ფასდაკლება!',
            icon: LucideIcons.percent,
          );
        } else {
          AppToast.success(
            context,
            '„${product.title}“ დაემატა კალათაში',
            icon: LucideIcons.shoppingBag,
          );
        }

        if (floatingCartKey != null &&
            buttonContext != null &&
            buttonContext.mounted) {
          FlyToCartAnimator.run(
            context: context,
            fromContext: buttonContext,
            toKey: floatingCartKey,
            quantity: addedQuantity,
            onComplete: () => floatingCartKey.currentState?.bounce(),
          );
        }
    }
  }

  static Future<void> _handleDifferentFarmer({
    required BuildContext context,
    required WidgetRef ref,
    required ProductModel product,
    required int quantity,
    required String currentFarmerName,
    required String newFarmerName,
    GlobalKey<DraggableFloatingCartState>? floatingCartKey,
    BuildContext? buttonContext,
  }) async {
    final confirmed = await AppConfirmationBottomSheet.showDifferentFarmerCart(
      context: context,
      currentFarmerName: currentFarmerName,
      newFarmerName: newFarmerName,
    );

    if (confirmed && context.mounted) {
      final retryResult = ref.read(cartProvider.notifier).addProduct(
            product,
            quantity,
            forceReplaceFarmer: true,
          );
      _handleResult(
        context: context,
        ref: ref,
        result: retryResult,
        product: product,
        quantity: quantity,
        floatingCartKey: floatingCartKey,
        buttonContext: buttonContext,
      );
    }
  }
}
