import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../orders/presentation/screens/farmer_order_detail_screen.dart';
import '../../domain/models/order_review_model.dart';
import '../providers/reviews_provider.dart';
import '../widgets/farmer_review_item_card.dart';

/// Dedicated Reviews & Rating screen for farmers to inspect, filter,
/// and track all received customer reviews and ratings.
class FarmerMyReviewsScreen extends ConsumerStatefulWidget {
  final String? farmerId;

  const FarmerMyReviewsScreen({
    super.key,
    this.farmerId,
  });

  @override
  ConsumerState<FarmerMyReviewsScreen> createState() =>
      _FarmerMyReviewsScreenState();
}

class _FarmerMyReviewsScreenState extends ConsumerState<FarmerMyReviewsScreen> {
  int? _selectedStarFilter; // null means "All"
  bool _isLoading = false;

  String? get _resolvedFarmerId {
    if (widget.farmerId != null && widget.farmerId!.isNotEmpty) {
      return widget.farmerId;
    }
    final authState = ref.read(authStateProvider);
    return authState.farmerId ?? authState.userId;
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final fid = _resolvedFarmerId;
    if (fid == null || fid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(reviewsProvider.notifier).loadReviewsForFarmer(fid);
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fid = _resolvedFarmerId ?? '';
    final reviewsState = ref.watch(reviewsProvider);
    final allReviews = reviewsState.reviewsByFarmer[fid] ?? const [];

    final marketplace = ref.watch(marketplaceProvider);
    final matchingFarmer = marketplace.farmers.where((f) => f.id == fid).firstOrNull;

    final displayReviewCount = allReviews.isNotEmpty
        ? allReviews.length
        : (matchingFarmer?.reviewCount ?? 0);

    final displayRating = displayReviewCount > 0
        ? (allReviews.isNotEmpty
            ? (allReviews.fold(0.0, (sum, r) => sum + r.rating) / allReviews.length)
            : (matchingFarmer?.rating ?? 0.0))
        : 0.0;

    final filteredReviews = _selectedStarFilter == null
        ? allReviews
        : allReviews.where((r) => r.rating == _selectedStarFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF0F172A),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Text(
              'ჩემი შეფასებები',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$displayReviewCount',
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadReviews,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Overall Rating Hero Card
            _buildRatingHeroCard(
              rating: displayRating,
              totalCount: displayReviewCount,
              reviews: allReviews,
            ),
            const SizedBox(height: 16),

            // 2. Star Filter Chips
            if (allReviews.isNotEmpty) ...[
              _buildStarFilterBar(allReviews),
              const SizedBox(height: 16),
            ],

            // 3. Reviews List or Empty State
            if (_isLoading && allReviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filteredReviews.isEmpty)
              _buildEmptyState(isFiltered: _selectedStarFilter != null)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  return FarmerReviewItemCard(
                    review: review,
                    showOrderBadge: true,
                    onOrderTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FarmerOrderDetailScreen(
                            orderId: review.orderId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingHeroCard({
    required double rating,
    required int totalCount,
    required List<OrderReviewModel> reviews,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Rating Score & Stars
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : '—',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ 5.0',
                        style: GoogleFonts.firaCode(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isFull = rating >= starValue;
                      final isHalf = rating >= starValue - 0.5 && !isFull;
                      return Icon(
                        isFull
                            ? Icons.star_rounded
                            : (isHalf
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded),
                        size: 20,
                        color: const Color(0xFFF59E0B),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCount > 0 ? '$totalCount შეფასების საფუძველზე' : 'შეფასებები არ არის',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Right: Trophy/Star decorative badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.award,
                  color: Color(0xFFD97706),
                  size: 30,
                ),
              ),
            ],
          ),

          // Rating Breakdown Bars (if reviews exist)
          if (totalCount > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              final star = 5 - index;
              final count = reviews.where((r) => r.rating == star).length;
              final fraction = totalCount > 0 ? (count / totalCount) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: GoogleFonts.firaCode(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            star >= 4
                                ? AppColors.primary
                                : (star == 3
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStarFilterBar(List<OrderReviewModel> reviews) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'ყველა (${reviews.length})',
            isSelected: _selectedStarFilter == null,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedStarFilter = null);
            },
          ),
          ...[5, 4, 3, 2, 1].map((star) {
            final count = reviews.where((r) => r.rating == star).length;
            if (count == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterChip(
                label: '$star',
                starIcon: true,
                count: count,
                isSelected: _selectedStarFilter == star,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedStarFilter =
                        _selectedStarFilter == star ? null : star;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    bool starIcon = false,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (starIcon) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.star_rounded,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFFF59E0B),
              ),
            ],
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: GoogleFonts.firaCode(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isFiltered}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered
                  ? LucideIcons.filter
                  : LucideIcons.messageSquareQuote,
              size: 36,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered
                ? 'ამ რეიტინგით შეფასებები არ მოიძებნა'
                : 'შეფასებები ჯერ არ არის',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'სცადეთ სხვა ფილტრის არჩევა.'
                : 'როდესაც მომხმარებლები შეასრულებენ და შეაფასებენ შეკვეთებს, მათი შეფასებები და კომენტარები აქ გამოჩნდება.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

