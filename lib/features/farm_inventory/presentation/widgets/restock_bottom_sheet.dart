import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../providers/farmer_inventory_provider.dart';

/// Modal Bottom Sheet for quickly restocking a product
class RestockBottomSheet extends ConsumerStatefulWidget {
  final ProductModel product;

  const RestockBottomSheet({
    super.key,
    required this.product,
  });

  static Future<void> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestockBottomSheet(product: product),
    );
  }

  @override
  ConsumerState<RestockBottomSheet> createState() => _RestockBottomSheetState();
}

class _RestockBottomSheetState extends ConsumerState<RestockBottomSheet> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '25');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRestock() async {
    final addQty = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (addQty <= 0) {
      AppToast.error(context, 'გთხოვთ მიუთითოთ დადებითი რაოდენობა');
      return;
    }

    final newTotal = await ref
        .read(farmerInventoryProvider.notifier)
        .restockProduct(widget.product.id, addQty);
    if (!mounted || newTotal == null) return;

    Navigator.of(context).pop();
    AppToast.success(
      context,
      'მარაგი შეივსო! ახალი ნაშთი: ${newTotal.toStringAsFixed(0)} ${widget.product.unit}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'მარაგის შევსება — ${product.title}',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'მიმდინარე მარაგი: ${product.stockQuantity.toStringAsFixed(0)} ${product.unit}',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [10, 25, 50, 100].map((preset) {
              final isSelected = _amountCtrl.text.trim() == '$preset';
              return ChoiceChip(
                label: Text(
                  '+$preset ${product.unit}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                onSelected: (_) {
                  setState(() => _amountCtrl.text = '$preset');
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            labelText: 'დასამატებელი რაოდენობა (${product.unit})',
            hintText: 'მაგ: 25',
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleRestock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(LucideIcons.packageCheck, size: 18),
              label: Text(
                'მარაგის დამატება',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

