import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../data/mock_data.dart';
import '../../data/models/category_model.dart';
import 'category_products_screen.dart';

/// Categories & Agro-Market screen (Option 1: Modern Fresh Bento):
/// - Unified AppHeader with title "აგრო მარკეტი", search bar, notifications & cart
/// - Bento style category cards with pastel organic tints, crisp dark typography,
///   semantic status dots, white-framed food photo showcase, and tactile arrow buttons.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = MockData.categories.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Unified App Header (Title, Search Bar, Notifications & Cart)
            AppHeader(
              title: 'აგრო მარკეტი',
              showNotificationBell: true,
              showCart: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              searchBar: AppSearchBar(
                controller: _searchController,
                hintText: 'მოძებნე კატეგორია ან პროდუქტი...',
                onChanged: (val) => setState(() => _searchQuery = val),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Subheader Info Row
                  if (filteredCategories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'კატეგორიები (${filteredCategories.length})',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.sparkles,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '100% ორგანული',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categories Grid or Empty State
                  if (filteredCategories.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.searchX,
                                size: 44,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'კატეგორია ვერ მოიძებნა',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.84,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final cat = filteredCategories[index];
                            return _CategoryBentoCard(
                              category: cat,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CategoryProductsScreen(category: cat),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: filteredCategories.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStyle {
  final Color bgStart;
  final Color bgEnd;
  final Color borderColor;
  final Color accentColor;

  const _BentoStyle({
    required this.bgStart,
    required this.bgEnd,
    required this.borderColor,
    required this.accentColor,
  });
}

/// Modern Fresh Bento Category Card (Wolt / Apple style)
class _CategoryBentoCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryBentoCard({
    required this.category,
    required this.onTap,
  });

  _BentoStyle _getStyle(String id) {
    switch (id) {
      case 'cat_fruit':
        return const _BentoStyle(
          bgStart: Color(0xFFFFF1F2),
          bgEnd: Color(0xFFFFE4E6),
          borderColor: Color(0xFFFECDD3),
          accentColor: Color(0xFFE11D48),
        );
      case 'cat_citrus':
        return const _BentoStyle(
          bgStart: Color(0xFFFFFBEB),
          bgEnd: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFDE68A),
          accentColor: Color(0xFFD97706),
        );
      case 'cat_berry':
        return const _BentoStyle(
          bgStart: Color(0xFFFDF2F8),
          bgEnd: Color(0xFFFCE7F3),
          borderColor: Color(0xFFFBCFE8),
          accentColor: Color(0xFFBE185D),
        );
      case 'cat_veg':
        return const _BentoStyle(
          bgStart: Color(0xFFF0FDF4),
          bgEnd: Color(0xFFDCFCE7),
          borderColor: Color(0xFFBBF7D0),
          accentColor: Color(0xFF0F766E),
        );
      case 'cat_dairy':
        return const _BentoStyle(
          bgStart: Color(0xFFFFFDF5),
          bgEnd: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFDE68A),
          accentColor: Color(0xFFB45309),
        );
      case 'cat_grain':
      default:
        return const _BentoStyle(
          bgStart: Color(0xFFFFF7ED),
          bgEnd: Color(0xFFFFEDD5),
          borderColor: Color(0xFFFED7AA),
          accentColor: Color(0xFFC2410C),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(category.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imgSize = (constraints.maxWidth * 0.52).clamp(74.0, 94.0);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.bgStart,
                  style.bgEnd,
                ],
              ),
              border: Border.all(
                color: style.borderColor,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: style.accentColor.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Decorative soft ambient circle in bottom corner for layered depth
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),

                // Top Content: Category Name + Count Dot Chip
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: style.accentColor.withValues(alpha: 0.20),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: style.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${category.productCount} პროდუქტი',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: style.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom-Right: Crisp Rounded Food Showcase Container
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: imgSize,
                    height: imgSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: category.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            category.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: style.bgEnd),
                          )
                        : Image.network(
                            category.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: style.bgEnd),
                          ),
                  ),
                ),

                // Bottom-Left: Subtle circular action arrow button
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: style.borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.arrowUpRight,
                        size: 14,
                        color: style.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
