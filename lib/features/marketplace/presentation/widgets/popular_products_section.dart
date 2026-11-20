import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animations/skeletons/product_card_skeleton.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_cart_helper.dart';
import '../providers/marketplace_provider.dart';
import '../providers/popular_products_provider.dart';
import '../screens/popular_products_screen.dart';
import '../screens/product_details_screen.dart';

/// Horizontal slider widget for Popular Products on HomeScreen
/// Follows Clean Architecture: watches topPopularProductsProvider and delegates actions
class PopularProductsSection extends ConsumerWidget {
  const PopularProductsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularProducts = ref.watch(topPopularProductsProvider);
    final isSyncing = ref.watch(marketplaceProvider).isSyncing;

    if (popularProducts.isEmpty && !isSyncing) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row with "ყველას ნახვა"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'პოპულარული პროდუქტები',
                style: AppTypography.h1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PopularProductsScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'ყველას ნახვა',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Product Cards List
        if (popularProducts.isEmpty)
          const SizedBox(
            height: 250,
            child: ProductGridSkeleton(itemCount: 3),
          )
        else
          SizedBox(
            height: 252,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: popularProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                final isOwner = product.isOwnedBy(
                  ref.watch(authStateProvider),
                );

                return SizedBox(
                  width: 168,
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
                        : (btnContext) => ProductCartHelper.handleAddToCart(
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
      ],
    );
  }
}
