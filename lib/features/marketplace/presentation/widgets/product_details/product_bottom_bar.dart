import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/primary_button.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';

/// Sticky Bottom Bar containing total price computation, strike-through original prices,
/// overlapping discount tag badge, and the "დამატება" PrimaryButton.
class ProductBottomBar extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final GlobalKey addButtonKey;
  final VoidCallback onAddToCart;
  final bool isOwner;

  const ProductBottomBar({
    super.key,
    required this.product,
    required this.quantity,
    required this.addButtonKey,
    required this.onAddToCart,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = !product.isAvailable || product.stockQuantity <= 0;
    final isBulkActive =
        product.hasBulkDiscount && quantity >= product.bulkDiscountMinQty!;
    final unitPrice = product.priceForQuantity(quantity);
    final totalPrice = unitPrice * quantity;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'სულ გადასახდელი:',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₾${totalPrice.toStringAsFixed(2)}',
                        style: AppTypography.h1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (isBulkActive) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₾${(product.price * quantity).toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ] else if (product.effectiveOriginalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₾${(product.effectiveOriginalPrice! * quantity).toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: PrimaryButton(
                  key: addButtonKey,
                  text: isOwner
                      ? 'თქვენი პროდუქტი'
                      : (isOutOfStock ? 'მარაგში აღარ არის' : 'დამატება'),
                  icon: isOwner
                      ? const Icon(
                          LucideIcons.ban,
                          size: 18,
                          color: Colors.white,
                        )
                      : (isOutOfStock
                          ? null
                          : const Icon(
                              LucideIcons.shoppingCart,
                              size: 20,
                              color: Colors.white,
                            )),
                  onPressed: (isOwner || isOutOfStock) ? null : onAddToCart,
                ),
              ),
            ],
          ),
        ),

        // Overlapping Discount Badge: half outside top border, half inside above button
        if (isBulkActive || product.hasDiscount)
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isBulkActive ? AppColors.primary : AppColors.accentWarm,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isBulkActive
                            ? AppColors.primary
                            : AppColors.accentWarm)
                        .withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBulkActive ? LucideIcons.boxes : LucideIcons.tag,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isBulkActive
                        ? '-${product.bulkDiscountPercent}% საბითუმო'
                        : '-${product.discountPercent}% ფასდაკლება',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
