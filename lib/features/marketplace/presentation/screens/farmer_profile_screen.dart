import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/product_card.dart';
import '../../data/mock_data.dart';
import '../../data/models/farmer_model.dart';
import 'product_details_screen.dart';

/// Farmer Profile Screen exactly matching Screenshot:
/// - Cover photo header with translucent back button, farm name & VAT badge
/// - White profile card with circular avatar, farmer name, location & 5-star ratings
/// - "გაიცანი ჩვენი ფერმერი" green CTA button
/// - "პროდუქტები" / "ფერმის შესახებ" tabs
/// - 2-column Grid of Product Cards
class FarmerProfileScreen extends ConsumerStatefulWidget {
  final FarmerModel farmer;

  const FarmerProfileScreen({super.key, required this.farmer});

  @override
  ConsumerState<FarmerProfileScreen> createState() =>
      _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends ConsumerState<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmer = widget.farmer;
    final farmerProducts = MockData.products
        .where((p) => p.farmerId == farmer.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // 1. Cover Photo Header with Back Button, Title & VAT badge
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.90),
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            title: Text(
              farmer.farmName,
              style: AppTypography.h1.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              if (farmer.isVatPayer)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.landmark,
                          size: 13,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'დღგ-ს გადამხდელი',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    farmer.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: AppColors.primaryLight),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.40),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. White Profile Card (Matching Screenshot)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              farmer.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.primaryLight),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Farmer Name & Location
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmer.farmerName,
                                style: AppTypography.h2.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      farmer.location,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    // Rating row
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star_rounded,
                            size: 19,
                            color: AppColors.rating,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${farmer.rating} (${farmer.reviewCount}) (${farmer.totalRatings} შეფასება)',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Action Button: "გაიცანი ჩვენი ფერმერი"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: PrimaryButton(
                text: 'გაიცანი ჩვენი ფერმერი',
                onPressed: () {
                  requireAuth(
                    context,
                    ref: ref,
                    onAuthenticated: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(farmer.farmName),
                          content: Text(farmer.about),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('დახურვა'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 4. Tab Bar (პროდუქტები / ფერმის შესახებ)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: AppTypography.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTypography.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'პროდუქტები'),
                  Tab(text: 'ფერმის შესახებ'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 5. Tab Content: Products Grid or About Section
          if (_selectedTabIndex == 0) ...[
            if (farmerProducts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 40,
                  ),
                  child: Center(
                    child: Text(
                      'ამ ფერმერს ჯერ არ აქვს დამატებული პროდუქტი.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.73,
                      ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = farmerProducts[index];
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
                    childCount: farmerProducts.length,
                  ),
                ),
              ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ფერმის ისტორია', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      farmer.about,
                      style: AppTypography.bodyMedium.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text('საკონტაქტო ინფორმაცია', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.phone,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          farmer.phone,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(farmer.location, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
