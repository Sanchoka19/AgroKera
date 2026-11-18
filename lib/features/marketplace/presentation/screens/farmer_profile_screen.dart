import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animations/staggered_entrance.dart';
import '../../../../core/widgets/draggable_floating_cart.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_cart_helper.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../../data/models/farmer_model.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_details/product_delivery_info_card.dart';
import 'product_details_screen.dart';

/// Farmer Profile Screen:
/// - Top AppBar with solid WHITE background (Back button & centered Farm Name)
/// - Tall cover photo (height: 240)
/// - Overlapping Farmer Profile Card: half on top of cover photo, half below
/// - Logical placement for VAT status ("დღგ-ს გადამხდელი") inside the profile card
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
  late final ScrollController _scrollController;
  final GlobalKey<DraggableFloatingCartState> _floatingCartKey = GlobalKey();
  DateTime _lastCartOpen = DateTime.fromMillisecondsSinceEpoch(0);
  int _selectedTabIndex = 0;
  double _scrollOffset = 0.0;

  void _openCart() {
    final now = DateTime.now();
    if (now.difference(_lastCartOpen).inMilliseconds < 400) return;
    _lastCartOpen = now;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset = _scrollController.hasClients
                ? _scrollController.offset
                : 0.0;
          });
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final cartCount = ref.watch(cartProvider).length;
    final headerProgress = ((_scrollOffset - 130) / 80).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      // 1. Dynamic AppBar: Transparent on cover photo, fades to white with Farm Name on scroll
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: headerProgress),
        surfaceTintColor: Colors.transparent,
        elevation: headerProgress > 0.9 ? 0.5 : 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: Colors.white.withValues(
                alpha: 0.9 * (1.0 - headerProgress * 0.9),
              ),
              shape: const CircleBorder(),
              elevation: (1.0 - headerProgress) * 2,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: headerProgress > 0.05
            ? Opacity(
                opacity: headerProgress,
                child: Text(
                  farmer.farmName,
                  style: AppTypography.h1.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Cover Photo with Parallax & Stretch Zoom + Half-Overlapping Profile Card
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Tall Cover Photo with Parallax & Stretch Zoom
                ClipRect(
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      _scrollOffset > 0
                          ? _scrollOffset * 0.45
                          : _scrollOffset,
                    ),
                    child: Transform.scale(
                      scale: _scrollOffset < 0
                          ? 1.0 + (-_scrollOffset / 320)
                          : 1.0,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: _scrollOffset < 0
                            ? 270 + (-_scrollOffset)
                            : 270,
                        width: double.infinity,
                        child: _buildCoverImage(farmer.coverUrl),
                      ),
                    ),
                  ),
                ),

                // Overlapping Farmer Profile Card: half on photo, half below
                Positioned(
                  bottom: -72,
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
                                child: _buildAvatarImage(farmer.avatarUrl),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Farm Name, Farmer Name, Location & VAT Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          farmer.farmName,
                                          style: AppTypography.h2.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Logical Placement 1: VAT badge on top right of profile card
                                      if (farmer.isVatPayer) ...[
                                        const SizedBox(width: 8),
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
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.user,
                                        size: 13.5,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          farmer.farmerName,
                                          style: AppTypography.caption
                                              .copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.mapPin,
                                        size: 13.5,
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
            const SizedBox(height: 86),

            // 3. Tab Bar (პროდუქტები / ფერმის შესახებ)
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
                      return StaggeredEntrance(
                        index: index,
                        child: ProductCard(
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
                          onAddWithContext: isOwner
                              ? null
                              : (btnContext) => ProductCartHelper.handleAddToCart(
                                    context: context,
                                    ref: ref,
                                    product: product,
                                    buttonContext: btnContext,
                                    floatingCartKey: _floatingCartKey,
                                  ),
                        ),
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
                    Text('მდებარეობა', style: AppTypography.h2),
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
      DraggableFloatingCart(
        key: _floatingCartKey,
        cartCount: cartCount,
        onTap: _openCart,
      ),
    ],
  ),
);
  }

  Widget _buildAvatarImage(String avatarUrl) {
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.primaryLight),
      );
    }
    if (avatarUrl.startsWith('data:image/')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: AppColors.primaryLight),
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(avatarUrl).existsSync()) {
      return Image.file(
        File(avatarUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.primaryLight),
      );
    }
    return Container(color: AppColors.primaryLight);
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
    if (coverUrl.startsWith('data:image/')) {
      try {
        final base64Str = coverUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: AppColors.primaryLight),
        );
      } catch (_) {}
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
