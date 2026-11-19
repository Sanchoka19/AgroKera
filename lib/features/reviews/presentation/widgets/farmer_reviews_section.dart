import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/data/models/farmer_model.dart';
import '../providers/reviews_provider.dart';
import 'farmer_review_item_card.dart';
import 'farmer_reviews_list_sheet.dart';

/// Reviews section shown on the farmer profile ("ფერმის შესახებ" tab).
/// Previews the top 3 reviews and allows viewing all reviews via a modal bottom sheet.
class FarmerReviewsSection extends ConsumerStatefulWidget {
  final FarmerModel farmer;

  const FarmerReviewsSection({
    super.key,
    required this.farmer,
  });

  @override
  ConsumerState<FarmerReviewsSection> createState() =>
      _FarmerReviewsSectionState();
}

class _FarmerReviewsSectionState extends ConsumerState<FarmerReviewsSection> {
  static const int _previewLimit = 3;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewsProvider.notifier).loadReviewsForFarmer(widget.farmer.id);
    });
  }

  void _openAllReviewsSheet({
    required List reviews,
    required double rating,
    required int reviewCount,
  }) {
    FarmerReviewsListSheet.show(
      context: context,
      farmer: widget.farmer,
      reviews: List.from(reviews),
      rating: rating,
      reviewCount: reviewCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(reviewsProvider);
    final reviews = reviewsState.reviewsByFarmer[widget.farmer.id] ?? const [];

    final displayReviewCount = reviews.isNotEmpty
        ? reviews.length
        : widget.farmer.reviewCount;
    final displayRating = displayReviewCount > 0
        ? (reviews.isNotEmpty
            ? (reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length)
            : widget.farmer.rating)
        : 0.0;

    final previewReviews = reviews.take(_previewLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Review Count Badge
        Row(
          children: [
            Expanded(
              child: Text(
                'მომხმარებელთა შეფასებები',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$displayReviewCount',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Summary Rating Card (shown when there are reviews)
        if (displayReviewCount > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayRating.toStringAsFixed(1),
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isFull = displayRating >= starValue;
                        final isHalf =
                            displayRating >= starValue - 0.5 && !isFull;

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
                      '$displayReviewCount შეფასება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.award,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Reviews List or Empty State
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.messageSquareQuote,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 10),
                Text(
                  'ამ ფერმერს ჯერ არ აქვს მომხმარებელთა შეფასებები.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Preview up to 3 reviews
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: previewReviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return FarmerReviewItemCard(review: previewReviews[index]);
            },
          ),

          // "View All Reviews" button if more than 3 reviews exist
          if (reviews.length > _previewLimit) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openAllReviewsSheet(
                reviews: reviews,
                rating: displayRating,
                reviewCount: displayReviewCount,
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ყველა შეფასების ნახვა (${reviews.length})',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
