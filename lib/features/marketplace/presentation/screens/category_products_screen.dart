import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../../core/widgets/product_card.dart';
import '../../data/mock_data.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'product_details_screen.dart';

/// Category Products Screen matching Screenshot 5:
/// - Back button & Category title ("ბოსტნეული")
/// - Search bar + Filter button
/// - 2-column Grid of Product Cards
/// - Floating Cart button with item count badge
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  String _searchQuery = '';
  String? _selectedRegion;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category.name;
  }

  @override
  Widget build(BuildContext context) {
    // Filter products
    List<ProductModel> products = MockData.products.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == null ||
          _selectedCategory == 'ყველა' ||
          p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.category.name,
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Search bar + Filter button row
              Row(
                children: [
                  Expanded(
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button
                  InkWell(
                    onTap: () {
                      FilterBottomSheet.show(
                        context,
                        initialRegion: _selectedRegion,
                        initialCategory: _selectedCategory,
                        onApply: (reg, cat) {
                          setState(() {
                            _selectedRegion = reg;
                            _selectedCategory = cat;
                          });
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Grid
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'პროდუქტები ვერ მოიძებნა',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 210,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.70,
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            onAddPressed: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.title} დამატებულია კალათაში!',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // Floating Cart Button with Badge
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            backgroundColor: AppColors.surface,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: () {
              requireAuth(
                context,
                ref: ref,
                onAuthenticated: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('კალათა გახსნილია!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              );
            },
            child: const Icon(
              LucideIcons.shoppingCart,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.accentWarm,
                shape: BoxShape.circle,
              ),
              child: Text(
                '3',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
