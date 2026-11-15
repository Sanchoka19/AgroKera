import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/product_card.dart';
import '../../data/models/farmer_model.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_details/product_delivery_info_card.dart';
import 'product_details_screen.dart';

/// Farmer Profile Screen:
/// - Top AppBar with solid WHITE background (Back button & centered Farm Name)
/// - Tall cover photo (height: 240)
/// - Overlapping Farmer Profile Card: half on top of cover photo, half below
/// - Logical placement for VAT status ("დღგ-ს გადამხდელი") inside the profile card
/// - "გაიცანი ჩვენი ფერმერი" CTA button
/// - TabBar: "პროდუქტები" & "ფერმის შესახებ"
/// - Unified single-scroll page without double scrollbars
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
    final marketplaceState = ref.watch(marketplaceProvider);
    final farmer = marketplaceState.farmers.firstWhere(
      (f) => f.id == widget.farmer.id,
      orElse: () => widget.farmer,
    );
    final farmerProducts = marketplaceState
        .availableProducts
        .where((p) => p.farmerId == farmer.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // 1. Top Bar with solid WHITE background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Cover Photo + Half-Overlapping Profile Card
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Tall Cover Photo (Thumb)
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: _buildCoverImage(farmer.coverUrl),
                ),

                // Overlapping Farmer Profile Card: half on photo, half below
                Positioned(
                  bottom: -65,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ],
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
                            // Name, Location & VAT Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          farmer.farmerName,
                                          style: AppTypography.h2.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // Logical Placement 1: VAT badge on top right of profile card
                                      if (farmer.isVatPayer)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F4FD),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.info
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                LucideIcons.landmark,
                                                size: 11,
                                                color: AppColors.info,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'დღგ',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: AppColors.info,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
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
                                          style: AppTypography.caption
                                              .copyWith(
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
              ],
            ),

            // Clearance for overlapping bottom half of the card
            const SizedBox(height: 80),

            // 3. Action Button: "გაიცანი ჩვენი ფერმერი"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 16),

            // 4. Tab Bar (პროდუქტები / ფერმის შესახებ)
            Padding(
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
            const SizedBox(height: 14),

            // 5. Tab Content: Products Grid or About Section
            if (_selectedTabIndex == 0) ...[
              if (farmerProducts.isEmpty)
                Padding(
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
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 210,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.70,
                        ),
                    itemCount: farmerProducts.length,
                    itemBuilder: (context, index) {
                      final product = farmerProducts[index];
                      final isOwner = product.isOwnedBy(
                        ref.watch(authStateProvider),
                      );
                      return ProductCard(
                        product: product,
                        isOwner: isOwner,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                        onAddPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ] else ...[
              Padding(
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
                    const SizedBox(height: 22),
                    Text('მიწოდების პირობები', style: AppTypography.h2),
                    const SizedBox(height: 10),
                    ProductDeliveryInfoCard(farmer: farmer, farmerId: farmer.id),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverUrl) {
    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.primaryLight),
      );
    }
    if (!kIsWeb && File(coverUrl).existsSync()) {
      return Image.file(
        File(coverUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.primaryLight),
      );
    }
    return Container(color: AppColors.primaryLight);
  }
}
