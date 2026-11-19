import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/models/farmer_order_model.dart';
import '../providers/reviews_provider.dart';
import 'order_review_bottom_sheet.dart';

/// Card displayed on completed order screens prompting the customer to rate the order,
/// or showing their submitted review once completed.
class OrderReviewPromptCard extends ConsumerWidget {
  final FarmerOrder order;

  const OrderReviewPromptCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.status != OrderStatus.completed) {
      return const SizedBox.shrink();
    }

    final reviewsState = ref.watch(reviewsProvider);
    final existingReview = reviewsState.reviewsByOrder[order.id];

    if (existingReview != null) {
      // Already reviewed view
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // Soft amber surface
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.star,
                size: 18,
                color: Color(0xFFD97706),
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
                        'თქვენი შეფასება: ${existingReview.rating}.0',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: List.generate(
                          existingReview.rating,
                          (_) => const Icon(
                            LucideIcons.star,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (existingReview.comment != null &&
                      existingReview.comment!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '"${existingReview.comment!}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        color: const Color(0xFFB45309),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: () => OrderReviewBottomSheet.show(
                context: context,
                order: order,
              ),
              child: Text(
                'შეცვლა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Unreviewed prompt view
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.star,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'შეკვეთა ჩაბარებულია!',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'გაგვიზიარეთ თქვენი აზრი ფერმერისა და პროდუქციის შესახებ',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => OrderReviewBottomSheet.show(
                context: context,
                order: order,
              ),
              icon: const Icon(LucideIcons.star, size: 16),
              label: Text(
                'შეაფასეთ შეკვეთა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

