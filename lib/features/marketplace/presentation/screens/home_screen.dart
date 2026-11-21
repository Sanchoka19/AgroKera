import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animations/skeletons/product_card_skeleton.dart';
import '../../../../core/widgets/animations/staggered_entrance.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_cart_helper.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/global_search_dialog.dart';
import '../widgets/guest_promo_banner.dart';
import '../widgets/nearby_farms_section.dart';
import '../widgets/popular_products_section.dart';
import '../widgets/quick_categories_bar.dart';
import '../../../reviews/presentation/widgets/pending_review_nudge_card.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  final List<String> _bannerImages = const [
    'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=1000&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=1000&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % _bannerImages.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isSyncing = ref.watch(marketplaceProvider.select((s) => s.isSyncing));
    final products = ref.watch(buyerProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Unified App Header (Logo, Search Bar, Notifications, Favorites & Cart)
            Container(
              color: AppColors.bgPrimary,
              child: AppHeader(
                showLogo: true,
                showNotificationBell: true,
                showCart: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                searchBar: AppSearchBar(
                  onTap: widget.onSearchTap ??
                      () => GlobalSearchDialog.show(context),
                  hintText: 'მოძებნე პროდუქტი, ფერმა ან კატეგორია...',
                ),
                actions: [
                  IconButton(
                    tooltip: 'რჩეულები',
                    onPressed: () {
                      requireAuth(
                        context,
                        ref: ref,
                        onAuthenticated: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      LucideIcons.heart,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Guest Promo Banner (if unauthenticated)
                    if (!authState.isAuthenticated) ...[
                      const GuestPromoBanner(),
                      const SizedBox(height: 16),
                    ],

                    // Pending Review Nudge Banner (if user has an unreviewed completed order)
                    const PendingReviewNudgeCard(),

                    // Hero Carousel Banner with Auto-slide & subtle blur
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _bannerController,
                              onPageChanged: (idx) {
                                setState(() => _currentBannerIndex = idx);
                              },
                              itemCount: _bannerImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppCachedImage(
                                      imageUrl: _bannerImages[index],
                                      fit: BoxFit.cover,
                                      iconSize: 40,
                                    ),
                                    // Optimized contrast gradient overlay without expensive raster blur pass
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.15),
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.35),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Carousel Indicator Dots
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _bannerImages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: index == _currentBannerIndex ? 18 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index == _currentBannerIndex
                                          ? AppColors.primary
                                          : Colors.white.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: "სწრაფი კატეგორიები" (Quick Categories Bar with custom SVGs)
              QuickCategoriesBar(
                onSeeAllTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Section 1: "ახლოს მდებარე" (Nearby Farms with Real Proximity Calculation)
              const NearbyFarmsSection(),
              const SizedBox(height: 20),

              // Section 2: "პოპულარული პროდუქტები" (Horizontal Slider with Ranking Algorithm)
              const PopularProductsSection(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),

                    // Section 3: "ყველა პროდუქტი"
                    Text(
                      'ყველა პროდუქტი',
                      style: AppTypography.h1.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Responsive grid of products (capped at 16 for clean layout)
                    if (products.isEmpty)
                      isSyncing
                          ? const ProductGridSkeleton(itemCount: 4)
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      AppAssets.emptyProducts,
                                      width: 150,
                                      height: 150,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'პროდუქტები ჯერ არ არის დამატებული',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                    else ...[
                      MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 210,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: products.take(16).length,
                          itemBuilder: (context, index) {
                        final product = products[index];
                        final isOwner = product.isOwnedBy(authState);
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
                                    ProductCartHelper.handleAddToCart(
                                      context: context,
                                      ref: ref,
                                      product: product,
                                      buttonContext: btnContext,
                                    ),
                          ),
                        );
                      },
                    ),
                  ),
                      if (products.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CategoriesScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'სრული კატალოგის ნახვა',
                                  style: AppTypography.button.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  LucideIcons.arrowRight,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
  }
}
