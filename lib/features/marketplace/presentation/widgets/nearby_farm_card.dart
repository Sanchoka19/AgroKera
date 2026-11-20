import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/profile_image_view.dart';
import '../../domain/services/farmer_proximity_service.dart';
import '../screens/farmer_profile_screen.dart';

/// Clean, split-view modern Farm Card with real distance & delivery indicators
/// Strictly adheres to:
/// - Zero emojis (pure Lucide vector icons)
/// - High legibility and contrast
/// - Decoupled presentation from business calculations
class NearbyFarmCard extends StatelessWidget {
  final FarmerDistanceInfo info;

  const NearbyFarmCard({
    super.key,
    required this.info,
  });

  Widget _buildCoverImage(String coverUrl) {
    return ProfileImageView.cover(
      coverUrl: coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmer = info.farmer;

    return Semantics(
      button: true,
      label: 'ფერმა ${farmer.farmName}, მანძილი ${info.formattedDistance}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FarmerProfileScreen(farmer: farmer),
            ),
          );
        },
        child: Container(
          width: 232,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP COVER IMAGE SECTION WITH BADGES
              SizedBox(
                height: 105,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverImage(farmer.coverUrl),

                    // Subtle bottom gradient for image contrast
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),

                    // Top-Left: Real Proximity Distance Pill (NO emojis)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 11,
                              color: Color(0xFF34D399),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              info.formattedDistance,
                              style: GoogleFonts.notoSansGeorgian(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top-Right: Verified Badge Pill
                    if (farmer.isVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.badgeCheck,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. BOTTOM DETAILS CARD SECTION
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Farm Name
                      Text(
                        farmer.farmName,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Location text with icon
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 11,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              farmer.location,
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Rating & Delivery Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 12,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                farmer.rating.toStringAsFixed(1),
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              if (farmer.reviewCount > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '(${farmer.reviewCount})',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 9.5,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Delivery / Pickup Tag (NO emojis, scaled down safely)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: farmer.isDeliveryEnabled
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      farmer.isDeliveryEnabled
                                          ? LucideIcons.truck
                                          : LucideIcons.store,
                                      size: 10,
                                      color: farmer.isDeliveryEnabled
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      farmer.isDeliveryEnabled
                                          ? 'მიწოდებით'
                                          : 'თვითგატანა',
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: farmer.isDeliveryEnabled
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }
}
