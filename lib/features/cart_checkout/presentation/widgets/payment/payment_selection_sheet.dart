import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/payment_method_model.dart';
import '../../providers/payment_provider.dart';

/// Clean, modular bottom sheet for choosing between Escrow Wire Transfer, Cash, or Card.
class PaymentSelectionSheet extends ConsumerStatefulWidget {
  const PaymentSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PaymentSelectionSheet(),
    );
  }

  @override
  ConsumerState<PaymentSelectionSheet> createState() =>
      _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends ConsumerState<PaymentSelectionSheet> {
  late PaymentMethodType _temporarySelected;

  @override
  void initState() {
    super.initState();
    _temporarySelected = ref.read(paymentProvider).selectedMethod;
  }

  Widget _buildMethodOption({
    required PaymentMethodType type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                type.icon,
                size: 19,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),

            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          type.label,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type.badgeText,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primaryDark
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.shortSubtitle,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Radio Indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.wallet,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'გადახდის მეთოდი',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Option 1: Escrow Bank Transfer
            _buildMethodOption(
              type: PaymentMethodType.bankTransfer,
              isSelected: _temporarySelected == PaymentMethodType.bankTransfer,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _temporarySelected = PaymentMethodType.bankTransfer);
              },
            ),
            const SizedBox(height: 10),

            // Option 2: Cash on Delivery / Pickup
            _buildMethodOption(
              type: PaymentMethodType.cash,
              isSelected: _temporarySelected == PaymentMethodType.cash,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _temporarySelected = PaymentMethodType.cash);
              },
            ),
            const SizedBox(height: 10),

            // Option 3: Card Payment
            _buildMethodOption(
              type: PaymentMethodType.card,
              isSelected: _temporarySelected == PaymentMethodType.card,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _temporarySelected = PaymentMethodType.card);
              },
            ),
            const SizedBox(height: 18),

            // Confirm Selection Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(paymentProvider.notifier)
                      .selectMethod(_temporarySelected);
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'არჩევა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
