import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../../profile/presentation/widgets/profile_image_view.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Card showing delivery destination, time slot window, farmer info (with avatar), and payment method info.
class OrderDeliveryInfoCard extends ConsumerWidget {
  final FarmerOrder order;

  const OrderDeliveryInfoCard({super.key, required this.order});

  void _onCopyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    AppToast.info(context, 'ფერმერის ნომერი დაკოპირდა: $phone');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFarmerName =
        order.farmerName != null && order.farmerName!.trim().isNotEmpty;
    final hasPhone = order.contactPhone.trim().isNotEmpty;

    final marketplace = ref.watch(marketplaceProvider);
    final matchedFarmer = marketplace.farmers.where((f) =>
        (order.farmerId != null && f.id == order.farmerId) ||
        (order.farmerName != null &&
            (f.farmName == order.farmerName || f.farmerName == order.farmerName))
    ).firstOrNull;

    final effectiveFarmerAvatar = (order.farmerAvatarUrl != null &&
            order.farmerAvatarUrl!.trim().isNotEmpty)
        ? order.farmerAvatarUrl!.trim()
        : matchedFarmer?.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'მიწოდების ინფორმაცია',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Farmer Identity Row with Farmer Avatar Photo
          if (hasFarmerName) ...[
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: (effectiveFarmerAvatar != null &&
                            effectiveFarmerAvatar.trim().isNotEmpty)
                        ? ProfileImageView.avatar(
                            avatarUrl: effectiveFarmerAvatar,
                            size: 40,
                            backgroundColor: const Color(0xFFF0FDF4),
                            iconColor: const Color(0xFF16A34A),
                          )
                        : Container(
                            color: const Color(0xFFF0FDF4),
                            alignment: Alignment.center,
                            child: Text(
                              order.farmerName!.isNotEmpty
                                  ? order.farmerName![0].toUpperCase()
                                  : 'ფ',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16A34A),
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
                        'ფერმერი / მეურნეობა',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        order.farmerName!,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPhone)
                  IconButton(
                    tooltip: 'ფერმერის ნომერი',
                    onPressed: () => _onCopyPhone(context, order.contactPhone),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDF4),
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    icon: const Icon(LucideIcons.phone, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
          ],

          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.deliveryAddress ?? 'თბილისი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),

          // Time Window Row (if specified)
          if (order.deliveryTimeWindow != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryTimeWindow!,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Payment Method Row
          Row(
            children: [
              const Icon(
                LucideIcons.creditCard,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.isBankTransfer
                      ? 'AgroKera Escrow'
                      : 'ნაღდი ანგარიშსწორება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),

          // Tracking Number Row (if available)
          if (order.trackingNumber != null &&
              order.trackingNumber!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  LucideIcons.hash,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'გზავნილის კოდი: ${order.trackingNumber}',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
