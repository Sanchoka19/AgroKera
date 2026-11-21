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
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../domain/models/product_filter_criteria.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'product_details_screen.dart';

/// Category Products Screen matching Screenshot 5:
/// - Back button & Category title ("ბოსტნეული")
/// - Search bar + Modular Filter button
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late ProductFilterCriteria _filterCriteria;
  DateTime _lastCartOpen = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _filterCriteria = ProductFilterCriteria(
      category: widget.category.name,
      sortBy: 'პოპულარული',
    );
  }

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

  void _onAddToCart(ProductModel product, BuildContext btnContext) {
    ProductCartHelper.handleAddToCart(
      context: context,
      ref: ref,
      product: product,
      floatingCartKey: _floatingCartKey,
      buttonContext: btnContext,
    );
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterCriteria = ProductFilterCriteria(
        category: widget.category.name,
        sortBy: 'პოპულარული',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(buyerProductsProvider);

    // Lookup farmer locations for region filter
    final farmers = ref.watch(marketplaceProvider).farmers;
    final farmerLocations = {for (final f in farmers) f.id: f.location};

    // Filter and sort products using clean domain logic
    List<ProductModel> products = _filterCriteria.filterProducts(
      allProducts,
      searchQuery: _searchQuery,
      farmerLocations: farmerLocations,
    );

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
              // Search bar + Modular Filter button row
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      hintText: 'მოძებნე ${widget.category.name}...',
                      onChanged: (val) =>
                          setState(() => _searchQuery = val),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Modular Filter button
                  FilterButton(
                    isActive:
                        _filterCriteria.hasActiveFiltersExcludingCategory(),
                    badgeCount:
                        _filterCriteria.activeCountExcludingCategory(),
                    onTap: () {
                      FilterBottomSheet.show(
                        context,
                        criteria: _filterCriteria,
                        showCategoryFilter: false,
                        onApplyCriteria: (newCriteria) {
                          setState(() {
                            _filterCriteria = newCriteria.copyWith(
                              category: widget.category.name,
                            );
                          });
                        },
                      );
                    },
                  ),
                ],
              ),

              // Active Filter Chips (only shown if user applies region, price, tag, or sort filters)
              if (_filterCriteria.hasActiveFiltersExcludingCategory()) ...[
                const SizedBox(height: 8),
                ActiveFilterChips(
                  criteria: _filterCriteria,
                  showCategory: false,
                  onClearAll: () {
                    setState(() {
                      _filterCriteria = ProductFilterCriteria(
                        category: widget.category.name,
                        sortBy: 'პოპულარული',
                      );
                    });
                  },
                  onClearRegion: () {
                    setState(() {
                      _filterCriteria =
                          _filterCriteria.copyWith(clearRegion: true);
                    });
                  },
                  onClearSort: () {
                    setState(() {
                      _filterCriteria =
                          _filterCriteria.copyWith(sortBy: 'პოპულარული');
                    });
                  },
                  onClearPrice: () {
                    setState(() {
                      _filterCriteria = _filterCriteria.copyWith(
                        clearMinPrice: true,
                        clearMaxPrice: true,
                      );
                    });
                  },
                  onClearBio: () {
                    setState(() {
                      _filterCriteria =
                          _filterCriteria.copyWith(isBioOnly: false);
                    });
                  },
                  onClearInStock: () {
                    setState(() {
                      _filterCriteria =
                          _filterCriteria.copyWith(inStockOnly: false);
                    });
                  },
                  onClearDiscount: () {
                    setState(() {
                      _filterCriteria =
                          _filterCriteria.copyWith(hasDiscountOnly: false);
                    });
                  },
                ),
              ],
              const SizedBox(height: 14),

              // Product Grid
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppAssets.emptyProducts,
                                width: 170,
                                height: 170,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'პროდუქტები ვერ მოიძებნა',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'არჩეული ძიებით შედეგები არ არის'
                                    : 'ამ კატეგორიაში პროდუქტი ჯერ არ არის დამატებული',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_filterCriteria.hasActiveFilters ||
                                  _searchQuery.isNotEmpty) ...[
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
                        padding: const EdgeInsets.only(bottom: 96),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
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
                                  : (btnContext) => _onAddToCart(
                                        product,
                                        btnContext,
                                      ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
          // Draggable Floating Cart widget
          DraggableFloatingCart(
            key: _floatingCartKey,
            onTap: _openCart,
          ),
        ],
      ),
    );
  }
}
