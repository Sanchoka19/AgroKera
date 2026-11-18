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

  void _onAddToCart(ProductModel product, BuildContext btnContext) {
    ProductCartHelper.handleAddToCart(
      context: context,
      ref: ref,
      product: product,
      floatingCartKey: _floatingCartKey,
      buttonContext: btnContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(buyerProductsProvider);
    final cartCount = ref.watch(cartProvider).length;
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
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '„$_searchQuery“-ის შესაბამისი პროდუქცია ამ კატეგორიაში არ მოიძებნა.'
                                    : 'ამ კატეგორიაში შესაბამისი პროდუქცია არ მოიძებნა.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
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
                          return StaggeredEntrance(
                            index: index,
                            child: ProductCard(
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
                            ),
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
        cartCount: cartCount,
        bottomOffset: 24.0,
        onTap: _openCart,
      ),
    ],
  ),
);
  }
}
