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

/// Farmer Profile Screen adhering to Screenshot 11:
/// - Cover photo + "🏛️ დღგ-ს გადამხდელი" VAT badge
/// - Farmer Avatar with white border + Farmer name & Location
/// - Rating with 5 stars: "4.9 (80) (120შეფასება)"
/// - Action button: "გაიცანი ჩვენი ფერმერი" (protected by requireAuth)
/// - Tabs: "პროდუქტები" & "ფერმის შესახებ"
/// - 2-column grid of farmer's products
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          farmer.farmName,
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image + VAT badge Stack
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Image.network(farmer.coverUrl, fit: BoxFit.cover),
                ),
                // VAT Payer Badge
                if (farmer.isVatPayer)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.landmark,
                            size: 14,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'დღგ-ს გადამხდელი',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Avatar and Farmer Name Row
                Positioned(
                  bottom: -35,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Name & Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              farmer.farmerName,
                              style: AppTypography.h1.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  farmer.location,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Rating Stars Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: AppColors.rating,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${farmer.rating} (${farmer.reviewCount}) (${farmer.totalRatings}შეფასება)',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Button: "გაიცანი ჩვენი ფერმერი"
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

            // Tab Bar
            TabBar(
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
            const SizedBox(height: 16),

            // Tab Views
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Products Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: farmerProducts.isEmpty
                        ? Center(
                            child: Text(
                              'ამ ფერმერს ჯერ არ აქვს დამატებული პროდუქტი.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: farmerProducts.length,
                            itemBuilder: (context, index) {
                              final product = farmerProducts[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailsScreen(
                                            product: product,
                                          ),
                                    ),
                                  );
                                },
                                onAddPressed: () {
                                  requireAuth(
                                    context,
                                    ref: ref,
                                    onAuthenticated: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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

                  // Tab 2: About Farm
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            Text(farmer.phone, style: AppTypography.bodyMedium),
                          ],
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
