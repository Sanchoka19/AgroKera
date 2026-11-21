import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Clean modular widget for toggling quick agricultural filters.
/// Zero emojis: Uses strict Lucide vector icons and clean Georgian typography.
class QuickFilterTogglesWidget extends StatelessWidget {
  final bool isBioOnly;
  final bool inStockOnly;
  final bool hasDiscountOnly;
  final ValueChanged<bool> onBioChanged;
  final ValueChanged<bool> onInStockChanged;
  final ValueChanged<bool> onDiscountChanged;

  const QuickFilterTogglesWidget({
    super.key,
    required this.isBioOnly,
    required this.inStockOnly,
    required this.hasDiscountOnly,
    required this.onBioChanged,
    required this.onInStockChanged,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'მახასიათებლები',
          style: AppTypography.titleMedium.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildToggleChip(
              label: 'ბიო / ორგანული',
              icon: LucideIcons.sprout,
              isSelected: isBioOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                onBioChanged(!isBioOnly);
              },
            ),
            _buildToggleChip(
              label: 'მარაგშია',
              icon: LucideIcons.packageCheck,
              isSelected: inStockOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                onInStockChanged(!inStockOnly);
              },
            ),
            _buildToggleChip(
              label: 'ფასდაკლებით',
              icon: LucideIcons.badgePercent,
              isSelected: hasDiscountOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                onDiscountChanged(!hasDiscountOnly);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
