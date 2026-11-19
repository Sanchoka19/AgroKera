import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/marketplace/data/models/product_model.dart';
import 'app_toast.dart';

/// Modal Bottom Sheet that prompts the user to select / confirm quantity
/// when a product has a minimum order requirement (`minOrderQuantity > 1`)
/// or when quick-adding from any product card.
class ProductQuickAddBottomSheet extends StatefulWidget {
  final ProductModel product;
  final void Function(int quantity) onConfirm;
  final VoidCallback? onOpenDetails;

  const ProductQuickAddBottomSheet({
    super.key,
    required this.product,
    required this.onConfirm,
    this.onOpenDetails,
  });

  static Future<void> show({
    required BuildContext context,
    required ProductModel product,
    required void Function(int quantity) onConfirm,
    VoidCallback? onOpenDetails,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ProductQuickAddBottomSheet(
          product: product,
          onConfirm: onConfirm,
          onOpenDetails: onOpenDetails,
        ),
      ),
    );
  }

  @override
  State<ProductQuickAddBottomSheet> createState() =>
      _ProductQuickAddBottomSheetState();
}

class _ProductQuickAddBottomSheetState
    extends State<ProductQuickAddBottomSheet> {
  late int _quantity;
  late final int _minLimit;
  late final int _maxStock;
  late final TextEditingController _qtyController;
  late final FocusNode _qtyFocusNode;

  @override
  void initState() {
    super.initState();
    _minLimit = widget.product.minOrderQuantity.toInt().clamp(1, 99999);
    _maxStock = widget.product.stockQuantity.toInt().clamp(1, 99999);
    _quantity = _minLimit;
    _qtyController = TextEditingController(text: '$_quantity');
    _qtyFocusNode = FocusNode();
    _qtyFocusNode.addListener(() {
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
  void dispose() {
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _commitTypedQuantity(String rawValue) {
    final parsed = int.tryParse(rawValue.trim());
    if (parsed == null) {
      _qtyController.text = '$_quantity';
      return;
    }

    if (parsed < _minLimit) {
      AppToast.info(
        context,
        'მინიმალური შეკვეთის რაოდენობაა ${widget.product.minOrderDisplay}',
        icon: LucideIcons.info,
      );
      setState(() {
        _quantity = _minLimit;
        _qtyController.text = '$_quantity';
      });
      return;
    }

    if (parsed > _maxStock) {
      AppToast.info(
        context,
        'მარაგში მხოლოდ $_maxStock ${widget.product.unit}-ია',
      );
      setState(() {
        _quantity = _maxStock;
        _qtyController.text = '$_quantity';
      });
      return;
    }

    setState(() {
      _quantity = parsed;
      _qtyController.text = '$_quantity';
    });
  }

  void _decrement() {
    if (_quantity <= _minLimit) {
      HapticFeedback.lightImpact();
      AppToast.info(
        context,
        'მინიმალური შეკვეთის რაოდენობაა ${widget.product.minOrderDisplay}',
        icon: LucideIcons.info,
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _quantity--;
      _qtyController.text = '$_quantity';
    });
  }

  void _increment() {
    if (_quantity >= _maxStock) {
      HapticFeedback.lightImpact();
      AppToast.info(context, 'მარაგში მეტი აღარ არის');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _quantity++;
      _qtyController.text = '$_quantity';
    });
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

  double _calculateSubtotal() {
    final product = widget.product;
    if (product.hasBulkDiscount &&
        product.bulkDiscountMinQty != null &&
        product.bulkDiscountPercent != null &&
        _quantity >= product.bulkDiscountMinQty!) {
      final discountFactor = (100 - product.bulkDiscountPercent!) / 100.0;
      return (_quantity * product.price * discountFactor);
    }
    return _quantity * product.price;
  }

  Widget _buildProductThumb(String url) {
    Widget fallback() => const Icon(
          LucideIcons.image,
          color: AppColors.textSecondary,
        );

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    if (url.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(url.split(',').last),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final subtotal = _calculateSubtotal();
    final hasBulkDiscountApplied = product.hasBulkDiscount &&
        product.bulkDiscountMinQty != null &&
        _quantity >= product.bulkDiscountMinQty!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Product Header Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.surfaceInput,
                    child: _buildProductThumb(product.imageUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.store,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.farmerName,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₾${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '/${product.unit}',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          if (product.effectiveOriginalPrice != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₾${product.effectiveOriginalPrice!.toStringAsFixed(0)}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Minimum order notice banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ფერმერის მიერ განსაზღვრული მინიმალური შეკვეთაა ${product.minOrderDisplay}.',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bulk discount highlight (if configured)
            if (product.hasBulkDiscount) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hasBulkDiscountApplied
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasBulkDiscountApplied
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasBulkDiscountApplied
                          ? LucideIcons.checkCircle2
                          : LucideIcons.flame,
                      size: 15,
                      color: hasBulkDiscountApplied
                          ? AppColors.primary
                          : const Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasBulkDiscountApplied
                          ? 'გააქტიურებულია ${product.bulkDiscountPercent}% საბითუმო ფასდაკლება!'
                          : '${product.bulkDiscountMinQty?.toInt()} ${product.unit}-დან მოქმედებს ${product.bulkDiscountPercent}% საბითუმო ფასდაკლება.',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasBulkDiscountApplied
                              ? const Color(0xFF065F46)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Quantity Selection Stepper Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'რაოდენობა:',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus Button
                    InkWell(
                      onTap: _decrement,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _quantity <= _minLimit
                                ? const Color(0xFFE2E8F0)
                                    .withValues(alpha: 0.6)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.minus,
                          size: 15,
                          color: _quantity <= _minLimit
                              ? AppColors.textSecondary
                                  .withValues(alpha: 0.35)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Editable Quantity Input with dynamic width
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
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 16,
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

                    // Plus Button
                    InkWell(
                      onTap: _increment,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _quantity >= _maxStock
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

            const SizedBox(height: 22),

            // Add to Cart Button
            ElevatedButton(
              onPressed: () {
                if (_qtyFocusNode.hasFocus) {
                  _commitTypedQuantity(_qtyController.text);
                  _qtyFocusNode.unfocus();
                }
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                widget.onConfirm(_quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.shoppingBag, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'კალათაში დამატება • ₾${subtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            if (widget.onOpenDetails != null) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onOpenDetails!();
                  },
                  child: Text(
                    'სრული დეტალების ნახვა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ),
),
);
  }
}
