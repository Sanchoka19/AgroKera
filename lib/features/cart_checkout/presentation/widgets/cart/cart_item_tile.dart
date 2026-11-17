import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import '../../providers/cart_provider.dart';

/// Card displaying product thumbnail, title, farmer, bulk discount and quantity stepper.
class CartItemTile extends ConsumerWidget {
  final CartItemModel item;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwn = ref.watch(authStateProvider).isOwnerOfCartItem(item);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwn ? const Color(0xFFFCA5A5) : const Color(0xFFF3F4F6),
          width: isOwn ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
              color: const Color(0xFFF3F4F6),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child:
                      Icon(LucideIcons.image, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product details & Stepper
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Red Trash Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onRemove();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          LucideIcons.trash2,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isOwn) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Text(
                      'თქვენი პროდუქტი (ამოიღეთ გასაგრძელებლად)',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 2),

                // Package Text
                if (item.packageText.isNotEmpty)
                  Text(
                    item.packageText,
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 2),

                // Farmer Name
                Text(
                  item.farmerName,
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 10),

                // Price Column (Left) and Stepper (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.totalPrice.toStringAsFixed(2)} ₾',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: item.isBulkDiscountApplied
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        if (item.isBulkDiscountApplied)
                          Text(
                            '${item.effectiveUnitPrice.toStringAsFixed(2)} ₾/${item.unit} (-${item.bulkDiscountPercent}%)',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Text(
                            '${item.pricePerUnit.toStringAsFixed(2)} ₾/${item.unit}',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),

                    // Stepper: [-] qty [+]
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.quantity <= item.minOrderQuantity) {
                                AppToast.info(
                                  context,
                                  'მინიმალური შეკვეთაა ${item.minOrderQuantity.toInt()} ${item.unit}',
                                );
                                return;
                              }
                              ref
                                  .read(cartProvider.notifier)
                                  .decrement(item.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Icon(
                                LucideIcons.minus,
                                size: 16,
                                color: item.quantity <= item.minOrderQuantity
                                    ? AppColors.textSecondary
                                        .withValues(alpha: 0.35)
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (item.quantity >= item.stockQuantity) {
                                AppToast.info(
                                  context,
                                  'მარაგში მხოლოდ ${item.stockQuantity.toInt()} ${item.unit}-ია',
                                );
                                return;
                              }
                              final success = ref
                                  .read(cartProvider.notifier)
                                  .increment(item.id);
                              if (!success) {
                                AppToast.info(
                                  context,
                                  'მარაგში მხოლოდ ${item.stockQuantity.toInt()} ${item.unit}-ია',
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Icon(
                                LucideIcons.plus,
                                size: 16,
                                color: item.quantity >= item.stockQuantity
                                    ? AppColors.textSecondary
                                        .withValues(alpha: 0.35)
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
