import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/status_badge.dart';
import 'package:agrokera/features/farm_inventory/presentation/widgets/product_steps/agro_tag_item.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';

/// Product title, origin location chip, rating, min-order badge, stock badge,
/// and agro characteristic tags.
class ProductHeaderInfo extends StatelessWidget {
  final ProductModel product;
  final String location;

  const ProductHeaderInfo({
    super.key,
    required this.product,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = !product.isAvailable || product.stockQuantity <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          product.title,
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        // Metadata Row: Origin, Rating & Stock Badges
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            // Origin / Location Chip
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            // Rating
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: AppColors.rating,
                ),
                const SizedBox(width: 3),
                Text(
                  '${product.rating}',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${product.reviewCount} შეფასება)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Min Order badge
            if (product.minOrderQuantity > 1)
              StatusBadge.warning(
                label: 'მინ. ${product.minOrderDisplay}',
                icon: const Icon(
                  LucideIcons.scale,
                  size: 12,
                  color: AppColors.accentWarm,
                ),
              ),

            // Stock status badge
            isOutOfStock
                ? StatusBadge.danger(
                    label: 'მარაგში აღარ არის',
                    icon: const Icon(
                      LucideIcons.x,
                      size: 12,
                      color: AppColors.accentWarm,
                    ),
                  )
                : StatusBadge.success(
                    label: product.stockStatus,
                    icon: const Icon(
                      LucideIcons.check,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
          ],
        ),

        // Agro Characteristics Tags
        if (product.effectiveAgroTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: product.effectiveAgroTags.map((tag) {
              final icon = AgroTagItem.iconFor(tag);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      tag,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
