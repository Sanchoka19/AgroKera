import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/marketplace/data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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
            // Top Image with Discount Badge (Takes available card image space)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl.startsWith('assets/')
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                      '${product.rating} (${product.reviewCount})',
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
                              color: product.stockStatus == 'მარაგშია'
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
                        if (isOwner) {
                          return InkWell(
                            onTap: () {
                              AppToast.info(
                                btnContext,
                                'საკუთარი პროდუქტის დამატება შეუძლებელია',
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.ban,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }
                        return InkWell(
                          onTap: () {
                            if (onAddWithContext != null) {
                              onAddWithContext!(btnContext);
                            } else if (onAddPressed != null) {
                              onAddPressed!();
                            } else {
                              onTap?.call();
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.plus,
                              size: 18,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
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
