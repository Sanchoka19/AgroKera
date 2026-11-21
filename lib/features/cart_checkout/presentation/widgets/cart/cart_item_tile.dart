import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/app_cached_image.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import '../../providers/cart_provider.dart';

/// Card displaying product thumbnail, title, bulk discount and editable quantity stepper.
class CartItemTile extends ConsumerStatefulWidget {
  final CartItemModel item;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  ConsumerState<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<CartItemTile> {
  late final TextEditingController _qtyController;
  late final FocusNode _qtyFocusNode;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.item.quantity}');
    _qtyFocusNode = FocusNode()
      ..addListener(() {
        if (!_qtyFocusNode.hasFocus) {
          _commitTypedQuantity(_qtyController.text);
        } else {
          _qtyController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _qtyController.text.length,
          );
        }
      });
  }

  @override
  void didUpdateWidget(covariant CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity &&
        !_qtyFocusNode.hasFocus &&
        _qtyController.text != '${widget.item.quantity}') {
      _qtyController.text = '${widget.item.quantity}';
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  double _calculateQtyWidth(String text) {
    final digits = text.isEmpty ? 1 : text.length;
    switch (digits) {
      case 1:
        return 20.0;
      case 2:
        return 28.0;
      case 3:
        return 36.0;
      default:
        return 44.0;
    }
  }

  void _commitTypedQuantity(String rawValue) {
    final item = widget.item;
    final parsed = int.tryParse(rawValue.trim());
    if (parsed == null) {
      _qtyController.text = '${item.quantity}';
      return;
    }

    final minQty = item.minOrderQuantity.toInt().clamp(1, 99999);
    final maxStock = item.stockQuantity.toInt().clamp(minQty, 99999);

    if (parsed < minQty) {
      AppToast.info(
        context,
        'მინიმალური შეკვეთაა $minQty ${item.unit}',
      );
    } else if (parsed > maxStock) {
      AppToast.info(
        context,
        'მარაგში მხოლოდ $maxStock ${item.unit}-ია',
      );
    }

    final clamped = parsed.clamp(minQty, maxStock);
    _qtyController.text = '$clamped';
    if (clamped != item.quantity) {
      ref.read(cartProvider.notifier).updateQuantity(item.id, clamped);
    }
  }

  Widget _buildThumbnail(String url) {
    return AppCachedImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fallbackIcon: LucideIcons.image,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isOwn = ref.watch(authStateProvider).isOwnerOfCartItem(item);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOwn
            ? Border.all(
                color: const Color(0xFFFCA5A5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
              child: _buildThumbnail(item.imageUrl),
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
                        widget.onRemove();
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
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
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

                    // Stepper: (-) qty (+) with circular buttons & spacing
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular Minus Button
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (item.quantity <= item.minOrderQuantity) {
                              AppToast.info(
                                context,
                                'მინიმალური შეკვეთაა ${item.minOrderQuantity.toInt()} ${item.unit}',
                              );
                              return;
                            }
                            ref.read(cartProvider.notifier).decrement(item.id);
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.minus,
                              size: 15,
                              color: item.quantity <= item.minOrderQuantity
                                  ? AppColors.textSecondary
                                      .withValues(alpha: 0.35)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),

                        // Editable Quantity Number in the middle with dynamic width
                        AnimatedBuilder(
                          animation: _qtyController,
                          builder: (context, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOutCubic,
                              height: 32,
                              width: _calculateQtyWidth(_qtyController.text),
                              alignment: Alignment.center,
                              child: child,
                            );
                          },
                          child: TextField(
                            controller: _qtyController,
                            focusNode: _qtyFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (val) {
                              _commitTypedQuantity(val);
                              _qtyFocusNode.unfocus();
                            },
                            onTapOutside: (_) {
                              if (_qtyFocusNode.hasFocus) {
                                _commitTypedQuantity(_qtyController.text);
                                _qtyFocusNode.unfocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 2),

                        // Circular Plus Button
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
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
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.quantity >= item.stockQuantity
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.plus,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
