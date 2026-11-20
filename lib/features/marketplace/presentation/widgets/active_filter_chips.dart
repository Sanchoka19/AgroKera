import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/product_filter_criteria.dart';

/// Reusable modular widget that displays active filter tags with quick dismissal.
class ActiveFilterChips extends StatelessWidget {
  final ProductFilterCriteria criteria;
  final VoidCallback onClearAll;
  final VoidCallback? onClearRegion;
  final VoidCallback? onClearCategory;
  final VoidCallback? onClearSort;

  const ActiveFilterChips({
    super.key,
    required this.criteria,
    required this.onClearAll,
    this.onClearRegion,
    this.onClearCategory,
    this.onClearSort,
  });

  @override
  Widget build(BuildContext context) {
    if (!criteria.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final hasRegion = criteria.region != null &&
        criteria.region != 'ყველა' &&
        criteria.region!.trim().isNotEmpty;
    final hasCategory = criteria.category != null &&
        criteria.category != 'ყველა' &&
        criteria.category!.trim().isNotEmpty;
    final hasSort = criteria.sortBy != 'პოპულარული';

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (hasRegion)
            _buildChip(
              label: 'რეგიონი: ${criteria.region}',
              onDelete: onClearRegion ?? onClearAll,
            ),
          if (hasCategory)
            _buildChip(
              label: 'კატეგორია: ${criteria.category}',
              onDelete: onClearCategory ?? onClearAll,
            ),
          if (hasSort)
            _buildChip(
              label: criteria.sortBy,
              onDelete: onClearSort ?? onClearAll,
            ),
          const SizedBox(width: 4),
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onClearAll();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'გასუფთავება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDelete();
              },
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

