import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_text_field.dart';

class ProductStep2Pricing extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final TextEditingController minOrderController;
  final VoidCallback onMinOrderIncrement;
  final VoidCallback onMinOrderDecrement;
  final bool isDiscountActive;
  final VoidCallback onToggleDiscount;
  final TextEditingController discountController;
  final bool isBulkDiscountActive;
  final VoidCallback onToggleBulkDiscount;
  final TextEditingController bulkMinQtyController;
  final TextEditingController bulkDiscountController;
  final double currentPrice;
  final double discountedPrice;
  final double bulkUnitPrice;

  static const List<String> availableUnits = [
    'კგ',
    'ცალი',
    'ბოთლი',
    'ყუთი',
    'ლიტრი',
  ];

  const ProductStep2Pricing({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.priceController,
    required this.stockController,
    required this.minOrderController,
    required this.onMinOrderIncrement,
    required this.onMinOrderDecrement,
    required this.isDiscountActive,
    required this.onToggleDiscount,
    required this.discountController,
    required this.isBulkDiscountActive,
    required this.onToggleBulkDiscount,
    required this.bulkMinQtyController,
    required this.bulkDiscountController,
    required this.currentPrice,
    required this.discountedPrice,
    required this.bulkUnitPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ფასი და მარაგის რაოდენობა',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'განსაზღვრეთ გასაყიდი ფასი, ერთეული და სურვილისამებრ ფასდაკლებები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Unit Selection (with runSpacing: 8 so wrapped chips never stick together!)
        Text(
          'საზომი ერთეული *',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableUnits.map((u) {
            final isSel = selectedUnit == u;
            return ChoiceChip(
              label: Text(
                u,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : const Color(0xFF334155),
                ),
              ),
              selected: isSel,
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (_) => onUnitChanged(u),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Price & Stock Row
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                labelText: 'ფასი (₾) *',
                hintText: 'მაგ: 4.50',
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(LucideIcons.banknote, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                labelText: 'მარაგი ($selectedUnit) *',
                hintText: 'მაგ: 50',
                controller: stockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(LucideIcons.package, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Minimum Order Quantity Card (Fully constrained with editable direct number typing!)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.scale,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'მინიმალური შეკვეთა',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'რა რაოდენობიდან იყიდება',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Stepper with editable input + unit
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onMinOrderDecrement,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.minus,
                        size: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Container(
                    height: 34,
                    constraints: const BoxConstraints(minWidth: 38, maxWidth: 54),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: minOrderController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text(
                    selectedUnit,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onMinOrderIncrement,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Discounts & Promotions Section Header
        Text(
          'აქციები და ფასდაკლებები (სურვილისამებრ)',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'დაამატეთ აქცია ან საბითუმო ფასი მხოლოდ იმ შემთხვევაში, თუ გსურთ',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 11.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // 1. Promo Discount Toggle Row
        _buildToggleCard(
          icon: LucideIcons.tag,
          title: 'ფასდაკლების აქცია',
          subtitle: 'დროებითი ფასდაკლება პროდუქტზე',
          isActive: isDiscountActive,
          onToggle: onToggleDiscount,
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'ფასდაკლება (%)',
                hintText: 'მაგ: 15',
                controller: discountController,
                keyboardType: TextInputType.number,
                fillColor: Colors.white,
                prefixIcon: const Icon(LucideIcons.percent, size: 16),
              ),
              if (currentPrice > 0 &&
                  discountController.text.isNotEmpty &&
                  (int.tryParse(discountController.text) ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.tag,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₾${currentPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.arrowRight,
                              size: 11,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'ახალი ფასი: ₾${discountedPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ),
        ),
        const SizedBox(height: 12),

        // 2. Bulk / Wholesale Discount Toggle Row
        _buildToggleCard(
          icon: LucideIcons.boxes,
          title: 'საბითუმო / მოცულობითი ფასი',
          subtitle: 'ფასდაკლება დიდი რაოდენობის შეძენისას',
          isActive: isBulkDiscountActive,
          onToggle: onToggleBulkDiscount,
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: 'ზღვარი ($selectedUnit-დან)',
                      hintText: 'მაგ: 10',
                      controller: bulkMinQtyController,
                      keyboardType: TextInputType.number,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(LucideIcons.scale, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      labelText: 'ფასდაკლება (%)',
                      hintText: 'მაგ: 20',
                      controller: bulkDiscountController,
                      keyboardType: TextInputType.number,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(LucideIcons.percent, size: 16),
                    ),
                  ),
                ],
              ),
              if (currentPrice > 0 &&
                  bulkMinQtyController.text.isNotEmpty &&
                  bulkDiscountController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.tag,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${bulkMinQtyController.text} $selectedUnit-დან: ₾${bulkUnitPrice.toStringAsFixed(2)}/$selectedUnit (-${bulkDiscountController.text}%)',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onToggle,
    required Widget expandedContent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: isActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F7EE)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 18,
                    color: isActive ? AppColors.primary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: isActive,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
          ),
          if (isActive) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFD1FAE5),
              ),
            ),
            expandedContent,
          ],
        ],
      ),
    );
  }
}
