import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../data/models/category_model.dart';
import 'category_products_screen.dart';

/// Categories & Agro-Market screen adhering to Screenshot 4:
/// - Title "აგრო მარკეტი"
/// - Search bar "ძებნა..."
/// - 2xN Grid of category cards with full-bleed photos & frosted glass blur text header
/// - Bottom padding so items never stick against the bottom navigation bar
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
        child: CustomScrollView(
          slivers: [
            // 1. Collapsible Title "აგრო მარკეტი": scrolls away on scroll down
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Center(
                  child: Text(
                    'აგრო მარკეტი',
                    style: AppTypography.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Sticky Search Bar: sticks to the top (top: 0) while scrolling
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchBarDelegate(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('categories_search_input'),
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'ძებნა...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Categories Grid or Empty State
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cat = filteredCategories[index];
                      return _CategoryCard(
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
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  static const double headerHeight = 64.0;

  _StickySearchBarDelegate({required this.child});

  @override
  double get minExtent => headerHeight;

  @override
  double get maxExtent => headerHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: overlapsContent
            ? Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: category.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-bleed background photo covering the entire card
            Positioned.fill(
              child: category.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: category.backgroundColor),
                    )
                  : Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: category.backgroundColor),
                    ),
            ),

            // 2. Lightened Frosted Glass Blur covering the ENTIRE card
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Category Title & Count directly on the blurred card
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
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${category.productCount} პროდუქტი',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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
