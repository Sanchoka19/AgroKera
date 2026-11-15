import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/draggable_floating_cart.dart';
import '../../../../core/widgets/fly_to_cart_animator.dart';
import '../../../../core/widgets/product_card.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'product_details_screen.dart';

/// Category Products Screen matching Screenshot 5:
/// - Back button & Category title ("ბოსტნეული")
/// - Search bar + Filter button
/// - 2-column Grid of Product Cards
/// - Floating Cart button with item count badge
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  final GlobalKey<DraggableFloatingCartState> _floatingCartKey = GlobalKey();
  String _searchQuery = '';
  String? _selectedRegion;
  String? _selectedCategory;
  DateTime _lastCartOpen = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category.name;
  }

  void _openCart() {
    final now = DateTime.now();
    if (now.difference(_lastCartOpen).inMilliseconds < 400) return;
    _lastCartOpen = now;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  Future<void> _handleDifferentFarmer(
    AddToCartDifferentFarmer diff,
    ProductModel product,
    BuildContext btnContext,
  ) async {
    final confirmed = await AppConfirmationBottomSheet.showDifferentFarmerCart(
      context: context,
      currentFarmerName: diff.currentFarmerName,
      newFarmerName: diff.newFarmerName,
    );

    if (confirmed && mounted && btnContext.mounted) {
      final retryResult = ref.read(cartProvider.notifier).addProduct(
            product,
            diff.quantity,
            forceReplaceFarmer: true,
          );
      _handleAddToCartResult(retryResult, product, btnContext);
    }
  }

  void _handleAddToCartResult(
    AddToCartResult result,
    ProductModel product,
    BuildContext btnContext,
  ) {
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
      case AddToCartDifferentFarmer():
        _handleDifferentFarmer(result, product, btnContext);
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
        }

        FlyToCartAnimator.run(
          context: context,
          fromContext: btnContext,
          toKey: _floatingCartKey,
          quantity: addedQuantity,
          onComplete: () => _floatingCartKey.currentState?.bounce(),
        );
    }
  }

  void _onAddToCart(ProductModel product, BuildContext btnContext) {
    if (ref.read(authStateProvider).isOwnerOfProduct(product)) {
      AppToast.error(context, 'საკუთარი პროდუქტის დამატება შეუძლებელია');
      return;
    }
    final addQty = product.minOrderQuantity.toInt().clamp(1, 99999);
    final result = ref.read(cartProvider.notifier).addProduct(product, addQty);
    _handleAddToCartResult(result, product, btnContext);
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(buyerProductsProvider);
    // Filter products
    List<ProductModel> products = allProducts.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == null ||
          _selectedCategory == 'ყველა' ||
          p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.category.name,
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
            children: [
              const SizedBox(height: 8),
              // Search bar + Filter button row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.search,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: AppTypography.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'ძებნა...',
                                hintStyle: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button
                  InkWell(
                    onTap: () {
                      FilterBottomSheet.show(
                        context,
                        initialRegion: _selectedRegion,
                        initialCategory: widget.category.name,
                        showCategoryFilter: false,
                        onApply: (reg, cat) {
                          setState(() {
                            _selectedRegion = reg;
                            _selectedCategory = widget.category.name;
                          });
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Grid
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'პროდუქტები ვერ მოიძებნა',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 210,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.70,
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isOwner = ref
                              .watch(authStateProvider)
                              .isOwnerOfProduct(product);
                          return ProductCard(
                            product: product,
                            isOwner: isOwner,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            onAddWithContext: isOwner
                                ? null
                                : (btnContext) =>
                                    _onAddToCart(product, btnContext),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      DraggableFloatingCart(
        key: _floatingCartKey,
        bottomOffset: 24.0,
        onTap: _openCart,
      ),
    ],
  ),
);
  }
}
