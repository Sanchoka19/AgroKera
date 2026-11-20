import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../orders/domain/models/farmer_order_model.dart';
import '../../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../../profile/presentation/widgets/profile_image_view.dart';
import '../providers/reviews_provider.dart';
import 'order_review_bottom_sheet.dart';

/// State notifier for tracking dismissed review prompt order IDs in the current session.
class DismissedReviewPromptsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void dismiss(String orderId) {
    state = {...state, orderId};
  }

  void dismissAll(Iterable<String> orderIds) {
    state = {...state, ...orderIds};
  }
}

final dismissedReviewPromptOrderIdsProvider =
    NotifierProvider<DismissedReviewPromptsNotifier, Set<String>>(
  DismissedReviewPromptsNotifier.new,
);

/// Clean, high-converting banner placed on the Home screen prompting the customer
/// to rate their recently completed order with the local farmer.
///
/// Features:
/// - Appears only when a completed client order has not been reviewed yet
/// - 1-Tap interactive stars immediately open [OrderReviewBottomSheet] with that rating
/// - Displays farmer avatar and farm name
/// - Dismissible via top-right 'X' icon
/// - Strictly zero emojis (uses Lucide vector icons)
class PendingReviewNudgeCard extends ConsumerWidget {
  const PendingReviewNudgeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated || auth.role != UserRole.customer) {
      return const SizedBox.shrink();
    }

    final clientOrders = ref.watch(farmerOrdersProvider).clientOrders;
    final reviewsState = ref.watch(reviewsProvider);
    final dismissedIds = ref.watch(dismissedReviewPromptOrderIdsProvider);

    // Find the most recent completed order without a review
    final pendingOrder = clientOrders.where((order) {
      return order.status == OrderStatus.completed &&
          order.review == null &&
          reviewsState.reviewsByOrder[order.id] == null &&
          !dismissedIds.contains(order.id);
    }).firstOrNull;

    if (pendingOrder == null) {
      return const SizedBox.shrink();
    }

    final marketplace = ref.watch(marketplaceProvider);
    final matchedFarmer = marketplace.farmers.where((f) =>
        (pendingOrder.farmerId != null && f.id == pendingOrder.farmerId) ||
        (pendingOrder.farmerName != null &&
            (f.farmName == pendingOrder.farmerName ||
                f.farmerName == pendingOrder.farmerName))
    ).firstOrNull;

    final effectiveFarmerAvatar = (pendingOrder.farmerAvatarUrl != null &&
            pendingOrder.farmerAvatarUrl!.trim().isNotEmpty)
        ? pendingOrder.farmerAvatarUrl!.trim()
        : matchedFarmer?.avatarUrl;

    final farmerName = pendingOrder.farmerName ?? 'ფერმერი';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft warm amber
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A), // Delicate amber border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Farmer avatar + Title + Dismiss button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: (effectiveFarmerAvatar != null &&
                          effectiveFarmerAvatar.trim().isNotEmpty)
                      ? ProfileImageView.avatar(
                          avatarUrl: effectiveFarmerAvatar,
                          size: 36,
                          backgroundColor: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                        )
                      : Container(
                          color: const Color(0xFFFEF3C7),
                          alignment: Alignment.center,
                          child: Text(
                            farmerName.isNotEmpty
                                ? farmerName[0].toUpperCase()
                                : 'ფ',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'როგორ მოგეწონათ შეკვეთა?',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      farmerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'დახურვა',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                splashRadius: 20,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(dismissedReviewPromptOrderIdsProvider.notifier)
                      .dismissAll(clientOrders.map((o) => o.id));
                },
                icon: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1-Tap 5-Star Row + Action CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Interactive 5 Stars
              Row(
                children: List.generate(5, (index) {
                  final starRating = index + 1;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      OrderReviewBottomSheet.show(
                        context: context,
                        order: pendingOrder,
                        initialRating: starRating,
                        onReviewSubmitted: () {
                          ref
                              .read(dismissedReviewPromptOrderIdsProvider.notifier)
                              .dismiss(pendingOrder.id);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      child: Icon(
                        LucideIcons.star,
                        size: 26,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  );
                }),
              ),

              // Quick CTA Button
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  OrderReviewBottomSheet.show(
                    context: context,
                    order: pendingOrder,
                    initialRating: 5,
                    onReviewSubmitted: () {
                      ref
                          .read(dismissedReviewPromptOrderIdsProvider.notifier)
                          .dismiss(pendingOrder.id);
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(LucideIcons.messageSquareQuote, size: 13),
                label: Text(
                  'შეაფასე',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
