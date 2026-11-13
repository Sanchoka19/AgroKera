import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/marketplace/data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Discount Badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.42,
                  child: product.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.surfaceInput,
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppColors.textSecondary,
                                  size: 28,
                                ),
                              ),
                        )
                      : Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.surfaceInput,
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppColors.textSecondary,
                                  size: 28,
                                ),
                              ),
                        ),
                ),
                if (product.discountPercent != null)
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

            // Details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                              '${product.rating} (${product.reviewCount})',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Stock status & Price + (+) Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.stockStatus,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: product.stockStatus == 'მარაგშია'
                                    ? AppColors.primary
                                    : AppColors.accentWarm,
                              ),
                            ),
                            Text(
                              '₾${product.price.toStringAsFixed(0)}/${product.unit}',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: onAddPressed,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.plus,
                              size: 17,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                      ],
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
