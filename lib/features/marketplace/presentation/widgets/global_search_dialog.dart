import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../data/models/farmer_model.dart';
import '../../data/models/product_model.dart';
import '../screens/farmer_profile_screen.dart';
import '../screens/product_details_screen.dart';

/// Global Search Dialog with frosted backdrop blur, dimmed scrim,
/// and live search over all products and farmers in AgroKera.
class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  /// Opens the modal dialog with backdrop blur & smooth entrance animation
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return const GlobalSearchDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6.0 * curved.value,
            sigmaY: 6.0 * curved.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  String _searchQuery = '';

  final List<String> _popularSuggestions = const [
    'პომიდორი',
    'კახური შავი ყურძენი',
    'მწვანე ლობიო',
    'მწვანილოვანი კომბოსტო',
    'ბულგარული წიწაკა',
    'ხახვი',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _onQueryChanged(suggestion);
  }

  void _navigateToProduct(ProductModel product) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _navigateToFarmer(FarmerModel farmer) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FarmerProfileScreen(farmer: farmer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();

    final matchingProducts = query.isEmpty
        ? <ProductModel>[]
        : MockData.products.where((p) {
            return p.title.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query) ||
                p.farmerName.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query);
          }).toList();

    final matchingFarmers = query.isEmpty
        ? <FarmerModel>[]
        : MockData.farmers.where((f) {
            return f.farmName.toLowerCase().contains(query) ||
                f.farmerName.toLowerCase().contains(query) ||
                f.location.toLowerCase().contains(query);
          }).toList();

    final hasResults =
        matchingProducts.isNotEmpty || matchingFarmers.isNotEmpty;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Search Bar Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.search,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            autofocus: true,
                            onChanged: _onQueryChanged,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'მოძებნე პროდუქტი ან ფერმერი...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onQueryChanged('');
                            },
                            tooltip: 'გასუფთავება',
                            icon: const Icon(
                              LucideIcons.delete,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'დახურვა',
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceInput,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: AppColors.border),

                  // 2. Body Area (Suggestions or Live Search Results)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: _searchQuery.isEmpty
                          ? _buildEmptyQuerySuggestions()
                          : (!hasResults
                              ? _buildNoResultsState()
                              : _buildSearchResults(
                                  matchingProducts,
                                  matchingFarmers,
                                )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Initial suggestions state when query is empty
  Widget _buildEmptyQuerySuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.sparkles,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'პოპულარული ძიებები',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSuggestions.map((suggestion) {
            return InkWell(
              onTap: () => _selectSuggestion(suggestion),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      suggestion,
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(
              LucideIcons.store,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'ფერმები',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...MockData.farmers.map((farmer) => _buildFarmerTile(farmer)),
      ],
    );
  }

  /// Empty state when no matches are found
  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.searchX,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'შედეგი ვერ მოიძებნა',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '„$_searchQuery“-ის შესაბამისი პროდუქტი ან ფერმერი არ არსებობს.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live search results
  Widget _buildSearchResults(
    List<ProductModel> products,
    List<FarmerModel> farmers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (products.isNotEmpty) ...[
          Text(
            'პროდუქტები (${products.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 6),
          ...products.map((product) => _buildProductTile(product)),
        ],
        if (farmers.isNotEmpty) ...[
          if (products.isNotEmpty) const SizedBox(height: 16),
          Text(
            'ფერმერები (${farmers.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 6),
          ...farmers.map((farmer) => _buildFarmerTile(farmer)),
        ],
      ],
    );
  }

  Widget _buildProductTile(ProductModel product) {
    return InkWell(
      onTap: () => _navigateToProduct(product),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            // Product image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceInput,
                  child: const Icon(
                    LucideIcons.image,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Farmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.store,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.farmerName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price & Discount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₾${product.price.toStringAsFixed(0)}/${product.unit}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (product.discountPercent != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentWarm.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${product.discountPercent}%',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentWarm,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerTile(FarmerModel farmer) {
    return InkWell(
      onTap: () => _navigateToFarmer(farmer),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(farmer.avatarUrl),
              onBackgroundImageError: (exception, stackTrace) {},
              child: const Icon(
                LucideIcons.user,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        farmer.farmName,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (farmer.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${farmer.farmerName} • ${farmer.location}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(
                  LucideIcons.star,
                  size: 14,
                  color: AppColors.rating,
                ),
                const SizedBox(width: 4),
                Text(
                  farmer.rating.toString(),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
