import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/animations/bounce_tap.dart';
import '../../../../reviews/presentation/providers/reviews_provider.dart';
import '../../../../reviews/presentation/widgets/order_review_bottom_sheet.dart';
import '../../../domain/models/farmer_order_model.dart';
import '../../screens/client_order_detail_screen.dart';
import '../../screens/order_chat_screen.dart';

/// Modern, ergonomic Client Order Card used on the "ჩემი შეკვეთები" screen.
class ClientOrderCard extends ConsumerWidget {
  final FarmerOrder order;

  const ClientOrderCard({
    super.key,
    required this.order,
  });

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientOrderDetailScreen(orderId: order.id),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderChatScreen(order: order),
      ),
    );
  }

  Widget _buildTrackingStep(String label, bool isDone) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.primary : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: isDone
              ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 10.5,
            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
            color: isDone ? AppColors.primary : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? AppColors.primary : const Color(0xFFE2E8F0),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepIndex = switch (order.status) {
      OrderStatus.pending => 1,
      OrderStatus.inProgress => 2,
      OrderStatus.completed => 3,
      OrderStatus.cancelled => 0,
    };

    final isCancelled = order.status == OrderStatus.cancelled;
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final extraCount = order.items.length - 1;
    final hasFarmerName =
        order.farmerName != null && order.farmerName!.trim().isNotEmpty;

    return BounceTap(
      onTap: () => _openDetails(context),
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCancelled ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isCancelled ? 0.02 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Farmer Name (or ID) + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.store,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasFarmerName ? order.farmerName! : 'აგროკერას ფერმერი',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: order.status.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    order.status.label,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: order.status.color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Order ID & Tracking Subtitle
            Row(
              children: [
                Text(
                  'შეკვეთა #${order.id}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${order.trackingNumber ?? 'AK-${order.id}'}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stepper (when not cancelled)
            if (!isCancelled) ...[
              Row(
                children: [
                  _buildTrackingStep('მოლოდინში', stepIndex >= 1),
                  _buildStepConnector(stepIndex >= 2),
                  _buildTrackingStep('დადასტურდა', stepIndex >= 2),
                  _buildStepConnector(stepIndex >= 3),
                  _buildTrackingStep('ჩაბარდა', stepIndex >= 3),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Products summary & Delivery details container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product item line with quantity badge
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.shoppingBag,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          firstItem != null
                              ? '${firstItem.name} (${firstItem.quantityText})'
                              : 'პროდუქცია',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (extraCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '+ კიდევ $extraCount',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Delivery Time Window (if specified)
                  if (order.deliveryTimeWindow != null &&
                      order.deliveryTimeWindow!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.deliveryTimeWindow!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Destination Address
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress ?? 'თბილისი',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contextual chip: PIN Code, Cash, or Escrow Status
            if (order.status == OrderStatus.inProgress) ...[
              const SizedBox(height: 10),
              if (order.isBankTransfer)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.keyRound,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ჩაბარების PIN: ',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                      Text(
                        order.deliveryPin,
                        style: GoogleFonts.firaCode(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.banknote,
                        size: 13,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ნაღდი ფული: ₾${order.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else if (order.status == OrderStatus.pending &&
                order.remainingCancellationTime.inMinutes > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'დასტურის ვადა: ~${order.remainingCancellationTime.inMinutes} წთ',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (order.status == OrderStatus.cancelled &&
                order.cancellationReason != null &&
                order.cancellationReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'გაუქმებულია: ${order.cancellationReason}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (order.status == OrderStatus.completed) ...[
              const SizedBox(height: 10),
              () {
                final review =
                    ref.watch(reviewsProvider).reviewsByOrder[order.id];
                if (review == null) {
                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      OrderReviewBottomSheet.show(
                        context: context,
                        order: order,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 15,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'შეაფასეთ ფერმერი და პროდუქტი',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: Color(0xFFB45309),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'შეფასებულია: ${review.rating}.0',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }(),
            ],

            const SizedBox(height: 12),

            // Total Sum
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'სრული ჯამი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₾${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Actions: Chat & Details Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(36),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(LucideIcons.messageSquare, size: 14),
                    label: Text(
                      'ჩათი',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(36),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(LucideIcons.arrowRight, size: 14),
                    label: Text(
                      'დეტალები',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
