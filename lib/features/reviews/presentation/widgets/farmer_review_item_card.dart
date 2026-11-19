import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/order_review_model.dart';
import 'star_rating_selector.dart';

/// Universal review card component used across AgroKera:
/// - Client-facing farm profile ("ფერმის შესახებ" tab)
/// - All reviews modal bottom sheet (FarmerReviewsListSheet)
/// - Farmer's personal reviews & rating management screen (FarmerMyReviewsScreen)
class FarmerReviewItemCard extends StatelessWidget {
  final OrderReviewModel review;
  final bool showOrderBadge;
  final VoidCallback? onOrderTap;

  const FarmerReviewItemCard({
    super.key,
    required this.review,
    this.showOrderBadge = false,
    this.onOrderTap,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _shortOrderId(String orderId) {
    return orderId.length > 5 ? orderId.substring(orderId.length - 5) : orderId;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(review.createdAt);
    final hasTags = review.tags.isNotEmpty;
    final hasComment = review.comment != null && review.comment!.trim().isNotEmpty;
    final hasOrderBadge = showOrderBadge && review.orderId.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar + Client Name + Date + Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
                          fontSize: 14,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.firaCode(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasOrderBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: onOrderTap,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${_shortOrderId(review.orderId)}',
                                    style: GoogleFonts.firaCode(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (onOrderTap != null) ...[
                                    const SizedBox(width: 2),
                                    const Icon(
                                      LucideIcons.chevronRight,
                                      size: 11,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StarRatingDisplay(
                rating: review.rating,
                size: 14,
              ),
            ],
          ),

          // 2. Feedback Tags (if customer selected any)
          if (hasTags) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // 3. Customer Comment Text
          if (hasComment) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                review.comment!.trim(),
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
