import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Clean modular widget for selecting sorting criteria.
class SortOptionsWidget extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortSelected;

  static const List<String> sortOptions = [
    'პოპულარული',
    'ჯერ იაფი',
    'ჯერ ძვირი',
    'მაღალი რეიტინგი',
  ];

  const SortOptionsWidget({
    super.key,
    required this.selectedSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'სორტირება',
          style: AppTypography.titleMedium.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortOptions.map((opt) {
            final isSelected = selectedSort == opt;
            return ChoiceChip(
              label: Text(opt),
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
                onSortSelected(opt);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
