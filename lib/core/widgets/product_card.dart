import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/marketplace/data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'animations/animated_add_to_cart_button.dart';
import 'animations/bounce_tap.dart';
import 'app_cached_image.dart';
import 'app_toast.dart';

/// Product card according to DESIGN_SYSTEM.md and Figma screenshots:
/// - Background: #FFFFFF
/// - Border: 1px #E2E2E2
/// - BorderRadius: 18
/// - Discount badge (-20%)
/// - Title, Farm info, Star rating, Stock status, Price and green (+) CTA
/// - Robust sizing to prevent any subpixel layout overflow
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddPressed;
  final void Function(BuildContext buttonContext)? onAddWithContext;
  final bool isOwner;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddPressed,
    this.onAddWithContext,
    this.isOwner = false,
  });

  Widget _buildProductImage(String url) {
    return AppCachedImage(
      imageUrl: url,
      fit: BoxFit.cover,
      iconSize: 28,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildProductImage(product.imageUrl);

    return BounceTap(
      onTap: onTap,
      scaleDown: 0.97,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Discount Badge (Takes available card image space)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageWidget,
                  if (isOwner)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.user,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'თქვენი',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (product.hasDiscount)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentWarm,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details section: Compact, fixed and solid gap
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product title
                Text(
                  product.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Farm Name with icon
                Row(
                  children: [
                    const Icon(
                      LucideIcons.store,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.farmerName,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Rating row
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.rating,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.reviewCount > 0
                          ? '${product.rating.toStringAsFixed(1)} (${product.reviewCount})'
                          : (product.rating > 0
                              ? product.rating.toStringAsFixed(1)
                              : 'ახალი'),
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Fixed solid gap between info and price
                const SizedBox(height: 8),

                // Stock status & Price + (+) Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.stockStatus,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: product.isOutOfStock
                                  ? const Color(0xFFDC2626)
                                  : product.stockStatus == 'მარაგშია'
                                      ? AppColors.primary
                                      : AppColors.accentWarm,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 2,
                            runSpacing: 1,
                            children: [
                              Text(
                                '₾${product.price.toStringAsFixed(0)}',
                                style: AppTypography.titleMedium.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '/${product.unit}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              if (product.effectiveOriginalPrice != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Text(
                                    '₾${product.effectiveOriginalPrice!.toStringAsFixed(0)}',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Builder(
                      builder: (btnContext) {
                        return AnimatedAddToCartButton(
                          isOwner: isOwner,
                          isOutOfStock: product.isOutOfStock,
                          onPressed: () {
                            if (isOwner) {
                              AppToast.info(
                                btnContext,
                                'საკუთარი პროდუქტის დამატება შეუძლებელია',
                              );
                            } else if (onAddWithContext != null) {
                              onAddWithContext!(btnContext);
                            } else if (onAddPressed != null) {
                              onAddPressed!();
                            } else {
                              onTap?.call();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
