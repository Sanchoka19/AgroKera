import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Clean modular widget for interactive price range filtering using RangeSlider.
class PriceRangeFilterWidget extends StatelessWidget {
  final double minLimit;
  final double maxLimit;
  final RangeValues currentRange;
  final ValueChanged<RangeValues> onChanged;

  const PriceRangeFilterWidget({
    super.key,
    this.minLimit = 0.0,
    this.maxLimit = 100.0,
    required this.currentRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startLabel = '${currentRange.start.round()} ₾';
    final endLabel = currentRange.end >= maxLimit
        ? '${maxLimit.round()}+ ₾'
        : '${currentRange.end.round()} ₾';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ფასი',
              style: AppTypography.titleMedium.copyWith(fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$startLabel - $endLabel',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            trackHeight: 4,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: RangeSlider(
            min: minLimit,
            max: maxLimit,
            divisions: 20,
            values: currentRange,
            onChanged: (values) {
              HapticFeedback.selectionClick();
              onChanged(values);
            },
          ),
        ),
      ],
    );
  }
}
