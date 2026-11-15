import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../../data/mock_data.dart';
import '../../data/models/product_model.dart';
import '../providers/marketplace_provider.dart';
import 'package:agrokera/core/widgets/draggable_floating_cart.dart';
import 'package:agrokera/core/widgets/fly_to_cart_animator.dart';
import '../widgets/product_details/product_bottom_bar.dart';
import '../widgets/product_details/product_delivery_info_card.dart';
import '../widgets/product_details/product_farmer_card.dart';
import '../widgets/product_details/product_header_info.dart';
import '../widgets/product_details/product_image_gallery.dart';
import '../widgets/product_details/product_quantity_section.dart';
import '../widgets/product_details/product_similar_carousel.dart';

/// Product Details Screen
/// High-performance, clean-architecture orchestrator coordinating modular sub-widgets:
/// - Pinned photo gallery with favorite/share controls
/// - Title, rating, badges, and agro-tags
/// - Direct keyboard & stepper quantity selection with quick chips
/// - Delivery methods & certification info
/// - Farmer profile mini-card
/// - Description & smart similar products carousel
/// - Draggable Floating Cart with snap physics & badge
/// - Sticky bottom checkout bar with Temu-style flying particle animation
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late int _quantity;
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey<DraggableFloatingCartState> _floatingCartKey = GlobalKey();

  DateTime _lastCartOpen = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minOrderQuantity.toInt().clamp(1, 99999);
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

  void _onAddToCart(ProductModel product) {
    if (ref.read(authStateProvider).isOwnerOfProduct(product)) {
      AppToast.error(context, 'საკუთარი პროდუქტის შეძენა შეუძლებელია');
      return;
    }

    final result =
        ref.read(cartProvider.notifier).addProduct(product, _quantity);

    switch (result) {
      case AddToCartOwnerForbidden():
        AppToast.error(context, 'საკუთარი პროდუქტის შეძენა შეუძლებელია');
      case AddToCartOutOfStock():
        AppToast.info(context, 'მარაგში მეტი აღარ არის');
      case AddToCartAlreadyMax(:final maxStock):
        AppToast.info(
          context,
          'ეს პროდუქტი უკვე მაქსიმალური რაოდენობით ($maxStock ${product.unit}) გაქვთ კალათაში',
        );
      case AddToCartSuccess(
          :final isCapped,
          :final addedQuantity,
          :final maxStock,
        ):
        if (isCapped) {
          AppToast.info(
            context,
            'მარაგის ლიმიტის გამო დაემატა $addedQuantity ${product.unit} (სულ კალათაში: $maxStock ${product.unit})',
          );
        }
        FlyToCartAnimator.run(
          context: context,
          fromKey: _addButtonKey,
          toKey: _floatingCartKey,
          quantity: addedQuantity,
          onComplete: () => _floatingCartKey.currentState?.bounce(),
        );
    }
  }

  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'აღწერა',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final marketplace = ref.watch(marketplaceProvider);
    final authState = ref.watch(authStateProvider);
    final isOwner = authState.isOwnerOfProduct(product);
    final cartCount = ref.watch(cartProvider).length;
    final similarProducts = ref.watch(similarProductsProvider(product));

    final farmer = marketplace.farmers.firstWhere(
      (f) =>
          f.id == product.farmerId ||
          f.farmName == product.farmerName ||
          f.farmerName == product.farmerName,
      orElse: () => marketplace.farmers.isNotEmpty
          ? marketplace.farmers.first
          : MockData.farmers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              ProductImageGallery(product: product),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductHeaderInfo(
                        product: product,
                        location: farmer.location,
                      ),
                      const SizedBox(height: 20),
                      ProductQuantitySection(
                        product: product,
                        quantity: _quantity,
                        isOwner: isOwner,
                        onQuantityChanged: (val) =>
                            setState(() => _quantity = val),
                      ),
                      const SizedBox(height: 20),
                      ProductDeliveryInfoCard(farmer: farmer, farmerId: farmer.id),
                      const SizedBox(height: 22),
                      ProductFarmerCard(farmer: farmer),
                      const SizedBox(height: 22),
                      _buildDescription(product.description),
                      ProductSimilarCarousel(products: similarProducts),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
          DraggableFloatingCart(
            key: _floatingCartKey,
            cartCount: cartCount,
            onTap: _openCart,
          ),
        ],
      ),
      bottomNavigationBar: ProductBottomBar(
        product: product,
        quantity: _quantity,
        addButtonKey: _addButtonKey,
        isOwner: isOwner,
        onAddToCart: () => _onAddToCart(product),
      ),
    );
  }
}
