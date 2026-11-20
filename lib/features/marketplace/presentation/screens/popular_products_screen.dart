import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animations/staggered_entrance.dart';
import '../../../../core/widgets/draggable_floating_cart.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_cart_helper.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../providers/popular_products_provider.dart';
import 'product_details_screen.dart';

/// Dedicated screen for displaying all popular products
/// Opened via "ყველას ნახვა" on the popular products section
class PopularProductsScreen extends ConsumerStatefulWidget {
  const PopularProductsScreen({super.key});

  @override
  ConsumerState<PopularProductsScreen> createState() =>
      _PopularProductsScreenState();
}

class _PopularProductsScreenState extends ConsumerState<PopularProductsScreen> {
  final GlobalKey<DraggableFloatingCartState> _floatingCartKey = GlobalKey();
  String _searchQuery = '';
  DateTime _lastCartOpen = DateTime.fromMillisecondsSinceEpoch(0);

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

  @override
  Widget build(BuildContext context) {
    final popularProducts = ref.watch(popularProductsProvider);
    final cartCount = ref.watch(cartProvider).length;

    final filteredProducts = popularProducts.where((p) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return p.title.toLowerCase().contains(q) ||
          p.farmerName.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'პოპულარული პროდუქტები',
                          style: AppTypography.h1.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _openCart,
                        icon: Badge(
                          isLabelVisible: cartCount > 0,
                          label: Text('$cartCount'),
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            LucideIcons.shoppingCart,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'მოძებნე პოპულარულ პროდუქტებში...',
                              hintStyle: GoogleFonts.notoSansGeorgian(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Product Grid or Empty State
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  AppAssets.emptyProducts,
                                  width: 140,
                                  height: 140,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'პროდუქტები ვერ მოიძებნა',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 210,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isOwner = product.isOwnedBy(
                              ref.watch(authStateProvider),
                            );

                            return StaggeredEntrance(
                              index: index,
                              child: ProductCard(
                                product: product,
                                isOwner: isOwner,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(
                                        product: product,
                                      ),
                                    ),
                                  );
                                },
                                onAddWithContext: isOwner
                                    ? null
                                    : (btnContext) =>
                                        ProductCartHelper.handleAddToCart(
                                          context: context,
                                          ref: ref,
                                          product: product,
                                          floatingCartKey: _floatingCartKey,
                                          buttonContext: btnContext,
                                        ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Floating Cart Button
          DraggableFloatingCart(
            key: _floatingCartKey,
            onTap: _openCart,
          ),
        ],
      ),
    );
  }
}
