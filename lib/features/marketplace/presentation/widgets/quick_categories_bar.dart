import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/category_model.dart';
import '../providers/popular_products_provider.dart';
import '../screens/category_products_screen.dart';

/// Popular Categories Bar for AgroKera HomeScreen:
/// Features:
/// - Displays Top 4 Popular Categories in a 100% responsive, non-scrolling single Row
/// - Each category takes an equal 25% share of width via Expanded
/// - Preserves identical pastel rounded square badge with custom SVG illustrations
/// - Direct one-tap navigation to CategoryProductsScreen
class QuickCategoriesBar extends ConsumerWidget {
  final VoidCallback? onSeeAllTap;

  const QuickCategoriesBar({
    super.key,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(topPopularCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'პოპულარული კატეგორიები',
                style: AppTypography.h1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (onSeeAllTap != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSeeAllTap?.call();
                  },
                  child: Row(
                    children: [
                      Text(
                        'ყველა',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Responsive Non-Scrolling 4-Category Row (25% each)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _QuickCategoryItem(
                    category: categories[i],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CategoryProductsScreen(
                            category: categories[i],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickCategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _QuickCategoryItem({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSvg = category.svgUrl != null && category.svgUrl!.isNotEmpty;

    return Semantics(
      button: true,
      label: 'კატეგორია ${category.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rounded Square Pastel Badge with Category SVG (identical design)
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: category.backgroundColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: category.backgroundColor.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: category.backgroundColor.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: hasSvg
                    ? SvgPicture.asset(
                        category.svgUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        category.imageUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // Category Name Label
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
