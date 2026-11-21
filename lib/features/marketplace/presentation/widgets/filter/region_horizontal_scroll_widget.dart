import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Clean modular single-row horizontal scroll widget displaying all active Georgian regions.
/// Non-blocking, responsive, zero vertical waste.
class RegionHorizontalScrollWidget extends StatelessWidget {
  final String selectedRegion;
  final ValueChanged<String> onRegionSelected;

  static const List<String> allRegions = [
    'ყველა',
    'კახეთი',
    'იმერეთი',
    'შიდა ქართლი',
    'ქვემო ქართლი',
    'აჭარა',
    'სამეგრელო',
    'გურია',
    'მცხეთა-მთიანეთი',
    'სამცხე-ჯავახეთი',
    'რაჭა-ლეჩხუმი',
  ];

  const RegionHorizontalScrollWidget({
    super.key,
    required this.selectedRegion,
    required this.onRegionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'რეგიონი',
          style: AppTypography.titleMedium.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allRegions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final reg = allRegions[index];
              final isSelected = selectedRegion == reg;

              return ChoiceChip(
                label: Text(reg),
                selected: isSelected,
                selectedColor: AppColors.primaryLight,
                backgroundColor: AppColors.surfaceInput,
                labelStyle: AppTypography.caption.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onRegionSelected(reg);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
