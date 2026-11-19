import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';

/// Quantity Stepper Card with Direct Keyboard Typing, Quick Step Chips (+5, +10, Max, Bulk)
/// and Bulk Discount Activation Card.
class ProductQuantitySection extends StatefulWidget {
  final ProductModel product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final bool isOwner;

  const ProductQuantitySection({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    this.isOwner = false,
  });

  @override
  State<ProductQuantitySection> createState() => _ProductQuantitySectionState();
}

class _ProductQuantitySectionState extends State<ProductQuantitySection> {
  late final TextEditingController _qtyController;
  late final FocusNode _qtyFocusNode;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.quantity}');
    _qtyFocusNode = FocusNode()
      ..addListener(() {
        if (!_qtyFocusNode.hasFocus) {
          final parsed =
              int.tryParse(_qtyController.text.trim()) ?? widget.quantity;
          _updateQuantity(parsed);
        } else {
          _qtyController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _qtyController.text.length,
          );
        }
      });
  }

  @override
  void didUpdateWidget(covariant ProductQuantitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity &&
        !_qtyFocusNode.hasFocus &&
        _qtyController.text != '${widget.quantity}') {
      _qtyController.text = '${widget.quantity}';
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

  void _updateQuantity(int newQty) {
    if (widget.isOwner) {
      AppToast.info(
        context,
        'საკუთარი პროდუქტის შეკვეთა შეუძლებელია',
      );
      return;
    }
    final minQty = widget.product.minOrderQuantity.toInt().clamp(1, 99999);
    final maxStock = widget.product.stockQuantity.toInt();
    if (newQty > maxStock && maxStock > 0) {
      AppToast.info(
        context,
        'მარაგში მხოლოდ $maxStock ${widget.product.unit}-ია',
      );
    }
    final clamped = newQty.clamp(minQty, maxStock > 0 ? maxStock : 1);
    _qtyController.text = '$clamped';
    widget.onQuantityChanged(clamped);
  }

  Widget _buildQuickStepChip(String label, int delta, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _updateQuantity(widget.quantity + delta),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOutOfStock = !product.isAvailable || product.stockQuantity <= 0;
    final isBulkActive =
        product.hasBulkDiscount && widget.quantity >= product.bulkDiscountMinQty!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isOwner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.shieldAlert,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ეს თქვენი მეურნეობის პროდუქტია — შეკვეთის გაფორმება შეუძლებელია',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'რაოდენობა (${product.unit}):',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'მარაგშია: ${product.stockQuantity.toInt()} ${product.unit}',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Stepper Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrement (Circular)
                      InkWell(
                        onTap: widget.isOwner
                            ? null
                            : () {
                                final minQty = product.minOrderQuantity
                                    .toInt()
                                    .clamp(1, 99999);
                                if (widget.quantity > minQty) {
                                  _updateQuantity(widget.quantity - 1);
                                } else {
                                  AppToast.info(
                                    context,
                                    'მინიმალური შეკვეთაა ${product.minOrderDisplay}',
                                  );
                                }
                              },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (widget.isOwner ||
                                      widget.quantity <=
                                          product.minOrderQuantity)
                                  ? AppColors.border.withValues(alpha: 0.4)
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.minus,
                            size: 16,
                            color: (widget.isOwner ||
                                    widget.quantity <= product.minOrderQuantity)
                                ? AppColors.textSecondary
                                    .withValues(alpha: 0.35)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),

                      // Direct Editable Number Input with dynamic width
                      AnimatedBuilder(
                        animation: _qtyController,
                        builder: (context, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            height: 34,
                            width: _calculateQtyWidth(_qtyController.text),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        child: TextField(
                          controller: _qtyController,
                          focusNode: _qtyFocusNode,
                          enabled: !widget.isOwner,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: widget.isOwner
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
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
                            final parsed =
                                int.tryParse(val.trim()) ?? widget.quantity;
                            _updateQuantity(parsed);
                            _qtyFocusNode.unfocus();
                          },
                          onTapOutside: (_) {
                            if (_qtyFocusNode.hasFocus) {
                              final parsed =
                                  int.tryParse(_qtyController.text.trim()) ??
                                      widget.quantity;
                              _updateQuantity(parsed);
                              _qtyFocusNode.unfocus();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 2),

                      // Increment (Circular)
                      InkWell(
                        onTap: (isOutOfStock || widget.isOwner)
                            ? null
                            : () {
                                final maxStock = product.stockQuantity.toInt();
                                if (widget.quantity < maxStock) {
                                  _updateQuantity(widget.quantity + 1);
                                } else {
                                  AppToast.info(
                                    context,
                                    'მარაგში მხოლოდ $maxStock ${product.unit}-ია',
                                  );
                                }
                              },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isOutOfStock ||
                                    widget.isOwner ||
                                    widget.quantity >= product.stockQuantity
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Quick Increment Helper Chips
              if (!isOutOfStock && !widget.isOwner) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (product.hasBulkDiscount &&
                        product.bulkDiscountMinQty != null)
                      InkWell(
                        onTap: () => _updateQuantity(
                          product.bulkDiscountMinQty!.toInt(),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isBulkActive
                                ? AppColors.primary
                                : const Color(0xFFE8F7EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.tag,
                                size: 12,
                                color: isBulkActive
                                    ? Colors.white
                                    : AppColors.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'საბითუმო (${product.bulkDiscountMinQty!.toInt()} ${product.unit})',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isBulkActive
                                      ? Colors.white
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _buildQuickStepChip('+5', 5),
                    _buildQuickStepChip('+10', 10),
                    if (product.stockQuantity > 25)
                      _buildQuickStepChip(
                        'მაქსიმუმი (${product.stockQuantity.toInt()})',
                        product.stockQuantity.toInt() - widget.quantity,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Bulk Discount Activation Card
        if (product.hasBulkDiscount) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isBulkActive
                  ? const Color(0xFFEBF7EF)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isBulkActive
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                width: isBulkActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isBulkActive
                        ? AppColors.primary
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.badgePercent,
                    size: 18,
                    color: isBulkActive
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'საბითუმო ფასდაკლება',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isBulkActive
                                  ? AppColors.primaryDark
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          if (isBulkActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'გააქტიურებულია',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.bulkDiscountMinQty?.toInt()} ${product.unit}-დან: ₾${product.bulkUnitPrice?.toStringAsFixed(2)}/${product.unit} (-${product.bulkDiscountPercent}%)',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: isBulkActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isBulkActive
                              ? AppColors.primaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
