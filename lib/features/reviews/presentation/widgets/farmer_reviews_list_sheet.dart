import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/data/models/farmer_model.dart';
import '../../domain/models/order_review_model.dart';
import 'farmer_review_item_card.dart';

/// Modal bottom sheet displaying all customer reviews for a farmer
/// with draggable scrolling, rating summary, and star rating filters.
class FarmerReviewsListSheet extends StatefulWidget {
  final FarmerModel farmer;
  final List<OrderReviewModel> reviews;
  final double rating;
  final int reviewCount;

  const FarmerReviewsListSheet({
    super.key,
    required this.farmer,
    required this.reviews,
    required this.rating,
    required this.reviewCount,
  });

  /// Opens the reviews modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required FarmerModel farmer,
    required List<OrderReviewModel> reviews,
    required double rating,
    required int reviewCount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FarmerReviewsListSheet(
        farmer: farmer,
        reviews: reviews,
        rating: rating,
        reviewCount: reviewCount,
      ),
    );
  }

  @override
  State<FarmerReviewsListSheet> createState() => _FarmerReviewsListSheetState();
}

class _FarmerReviewsListSheetState extends State<FarmerReviewsListSheet> {
  int? _selectedStarFilter; // null means "All"

  List<OrderReviewModel> get _filteredReviews {
    if (_selectedStarFilter == null) {
      return widget.reviews;
    }
    return widget.reviews
        .where((r) => r.rating == _selectedStarFilter)
        .toList();
  }

  int _countForStar(int star) {
    return widget.reviews.where((r) => r.rating == star).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReviews;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Fixed Header Section (Surface container with soft shadow)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Bar + Close Button
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'მომხმარებელთა შეფასებები',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.reviews.length}',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          tooltip: 'დახურვა',
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Overall Rating Summary Row
                    Row(
                      children: [
                        Text(
                          widget.rating > 0
                              ? widget.rating.toStringAsFixed(1)
                              : '0.0',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            final isFull = widget.rating >= starValue;
                            final isHalf =
                                widget.rating >= starValue - 0.5 && !isFull;
                            return Icon(
                              isFull
                                  ? Icons.star_rounded
                                  : (isHalf
                                      ? Icons.star_half_rounded
                                      : Icons.star_border_rounded),
                              size: 18,
                              color: const Color(0xFFF59E0B),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${widget.reviews.length} შეფასება)',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Star Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'ყველა (${widget.reviews.length})',
                            isSelected: _selectedStarFilter == null,
                            onTap: () => setState(() => _selectedStarFilter = null),
                          ),
                          const SizedBox(width: 6),
                          for (int s = 5; s >= 1; s--) ...[
                            _buildFilterChip(
                              label: '$s ვარსკვლავი (${_countForStar(s)})',
                              isSelected: _selectedStarFilter == s,
                              onTap: () => setState(() => _selectedStarFilter = s),
                            ),
                            if (s > 1) const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Scrollable Reviews List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.messageSquareQuote,
                                  size: 26,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedStarFilter != null
                                    ? 'არჩეული რეიტინგით შეფასებები არ მოიძებნა'
                                    : 'შეფასებები არ არის',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return FarmerReviewItemCard(review: filtered[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
