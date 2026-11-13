import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../../core/widgets/product_card.dart';
import '../../data/mock_data.dart';
import '../widgets/global_search_dialog.dart';
import '../widgets/guest_promo_banner.dart';
import 'farmer_profile_screen.dart';
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

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // App Bar: Logo + Search, Wishlist & Cart Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppLogo(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: widget.onSearchTap ??
                                  () => GlobalSearchDialog.show(context),
                              icon: const Icon(
                                LucideIcons.search,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                requireAuth(
                                  context,
                                  ref: ref,
                                  onAuthenticated: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('სურვილების სია გახსნილია'),
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
                            IconButton(
                              onPressed: () {
                                requireAuth(
                                  context,
                                  ref: ref,
                                  onAuthenticated: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('კალათა გახსნილია'),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(
                                LucideIcons.shoppingCart,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Guest Promo Banner (if unauthenticated)
                    if (!authState.isAuthenticated) ...[
                      const GuestPromoBanner(),
                      const SizedBox(height: 16),
                    ],

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
                                    Image.network(
                                      _bannerImages[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        color: AppColors.surfaceInput,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          LucideIcons.image,
                                          color: AppColors.textSecondary,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    // Subtle blur overlay as requested by user
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 1.5,
                                        sigmaY: 1.5,
                                      ),
                                      child: Container(
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
                    const SizedBox(height: 22),

                    // Section 1: "ახლოს მდებარე" (Nearby Farms)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ახლოს მდებარე',
                          style: AppTypography.h1.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Horizontal list of farms (Edge-to-edge scrolling with 16px start/end insets)
              SizedBox(
                height: 145,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: MockData.farmers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final farmer = MockData.farmers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FarmerProfileScreen(farmer: farmer),
                          ),
                        );
                      },
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Image.network(
                              farmer.coverUrl,
                              height: 145,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 145,
                                width: 200,
                                color: AppColors.surfaceInput,
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppColors.textSecondary,
                                  size: 32,
                                ),
                              ),
                            ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.70),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.badgeCheck,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farmer.farmName,
                                      style:
                                          AppTypography.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      farmer.location,
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),

                    // Section 2: "პოპულარული პროდუქტები"
                    Text(
                      'პოპულარული პროდუქტები',
                      style: AppTypography.h1.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2-column grid of products
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.64,
                      ),
                      itemCount: MockData.products.length,
                      itemBuilder: (context, index) {
                        final product = MockData.products[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          onAddPressed: () {
                            requireAuth(
                              context,
                              ref: ref,
                              onAuthenticated: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.title} დამატებულია კალათაში!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
