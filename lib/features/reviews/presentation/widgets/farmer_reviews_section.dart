import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/data/models/farmer_model.dart';
import '../providers/reviews_provider.dart';
import 'star_rating_selector.dart';

/// Reviews section shown on the farmer profile ("ფერმის შესახებ" tab)
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewsProvider.notifier).loadReviewsForFarmer(widget.farmer.id);
    });
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'მომხმარებელთა შეფასებები',
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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

        // Summary Rating Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
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
                      final isHalf = displayRating >= starValue - 0.5 && !isFull;

                      return Icon(
                        isFull
                            ? Icons.star_rounded
                            : (isHalf ? Icons.star_half_rounded : Icons.star_border_rounded),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
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

        // Reviews List or Empty State
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final dateStr =
                  '${review.createdAt.day}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: review.clientAvatarUrl != null &&
                                  review.clientAvatarUrl!.isNotEmpty
                              ? NetworkImage(review.clientAvatarUrl!)
                              : null,
                          child: review.clientAvatarUrl == null ||
                                  review.clientAvatarUrl!.isEmpty
                              ? Text(
                                  review.clientName.isNotEmpty
                                      ? review.clientName[0].toUpperCase()
                                      : 'მ',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.clientName,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                dateStr,
                                style: GoogleFonts.firaCode(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StarRatingDisplay(
                          rating: review.rating,
                          size: 14,
                        ),
                      ],
                    ),
                    if (review.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: review.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (review.comment != null &&
                        review.comment!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.comment!.trim(),
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12.5,
                          height: 1.4,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
