import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/category_model.dart';
import '../screens/category_products_screen.dart';

/// Quick Categories Bar for AgroKera HomeScreen
/// Features:
/// - Horizontal edge-to-edge scroll with smooth tactile tap
/// - Clean pastel circular badges with custom SVG vector illustrations
/// - Direct one-tap navigation to CategoryProductsScreen
class QuickCategoriesBar extends StatelessWidget {
  final VoidCallback? onSeeAllTap;

  const QuickCategoriesBar({
    super.key,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AppCategories.categories;

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
                'სწრაფი კატეგორიები',
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

        // Horizontal Categories List
        SizedBox(
          height: 98,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _QuickCategoryItem(
                category: category,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        category: category,
                      ),
                    ),
                  );
                },
              );
            },
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
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rounded Square Pastel Badge with Category SVG
              Container(
                width: 62,
                height: 62,
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
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          category.imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 7),

              // Category Name Label
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

