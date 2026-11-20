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
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/draggable_floating_cart.dart';
import '../../../../core/widgets/filter_button.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_cart_helper.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../../domain/models/product_filter_criteria.dart';
import '../providers/marketplace_provider.dart';
import '../providers/popular_products_provider.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'product_details_screen.dart';

/// Dedicated screen for displaying all popular products.
/// Includes modular search, filter by region/category/sort, and active filter chips.
class PopularProductsScreen extends ConsumerStatefulWidget {
  const PopularProductsScreen({super.key});

  @override
  ConsumerState<PopularProductsScreen> createState() =>
      _PopularProductsScreenState();
}

class _PopularProductsScreenState extends ConsumerState<PopularProductsScreen> {
  final GlobalKey<DraggableFloatingCartState> _floatingCartKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductFilterCriteria _filterCriteria = const ProductFilterCriteria.empty();
  DateTime _lastCartOpen = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterCriteria = const ProductFilterCriteria.empty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final popularProducts = ref.watch(popularProductsProvider);
    final cartCount = ref.watch(cartProvider).length;

    // Build farmer location lookup for accurate region filtering
    final farmers = ref.watch(marketplaceProvider).farmers;
    final farmerLocations = {for (final f in farmers) f.id: f.location};

    // Filter and sort popular products using clean domain logic
    final filteredProducts = _filterCriteria.filterProducts(
      popularProducts,
      searchQuery: _searchQuery,
      farmerLocations: farmerLocations,
    );

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

                // Search Bar + Modular Filter Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSearchBar(
                          controller: _searchController,
                          hintText: 'მოძებნე პოპულარულ პროდუქტებში...',
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilterButton(
                        isActive: _filterCriteria.hasActiveFilters,
                        badgeCount: _filterCriteria.activeCount,
                        onTap: () {
                          FilterBottomSheet.show(
                            context,
                            criteria: _filterCriteria,
                            onApplyCriteria: (newCriteria) {
                              setState(() => _filterCriteria = newCriteria);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Active Filter Chips
                if (_filterCriteria.hasActiveFilters) ...[
                  const SizedBox(height: 2),
                  ActiveFilterChips(
                    criteria: _filterCriteria,
                    onClearAll: () {
                      setState(() {
                        _filterCriteria = const ProductFilterCriteria.empty();
                      });
                    },
                    onClearRegion: () {
                      setState(() {
                        _filterCriteria =
                            _filterCriteria.copyWith(clearRegion: true);
                      });
                    },
                    onClearCategory: () {
                      setState(() {
                        _filterCriteria =
                            _filterCriteria.copyWith(clearCategory: true);
                      });
                    },
                    onClearSort: () {
                      setState(() {
                        _filterCriteria =
                            _filterCriteria.copyWith(sortBy: 'პოპულარული');
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                ],

                const SizedBox(height: 4),

                // Product Grid or Empty State
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
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
                                if (_filterCriteria.hasActiveFilters ||
                                    _searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'სცადეთ შეცვალოთ ან გაასუფთავოთ არჩეული ფილტრები',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _clearAllFilters,
                                    icon: const Icon(
                                      LucideIcons.rotateCcw,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    label: Text(
                                      'ფილტრების გასუფთავება',
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
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
