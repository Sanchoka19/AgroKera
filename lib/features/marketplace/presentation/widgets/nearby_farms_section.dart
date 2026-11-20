import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/marketplace_provider.dart';
import '../providers/nearby_farmers_provider.dart';
import 'nearby_farm_card.dart';

/// Clean orchestrator widget for the Nearby Farms section on HomeScreen
/// Decoupled from page layout: watches nearbyFarmersProvider and renders sorted cards
class NearbyFarmsSection extends ConsumerWidget {
  const NearbyFarmsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyState = ref.watch(nearbyFarmersProvider);
    final isSyncing = ref.watch(marketplaceProvider).isSyncing;
    final farmers = nearbyState.farmers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row (Title & Origin badge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ახლოს მდებარე',
                style: AppTypography.h1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  nearbyState.originDescription,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal List of Nearby Farm Cards
        if (farmers.isEmpty)
          SizedBox(
            height: 100,
            child: Center(
              child: isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'ფერმები ჯერ არ არის დამატებული',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          )
        else
          SizedBox(
            height: 185,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: farmers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final info = farmers[index];
                return NearbyFarmCard(info: info);
              },
            ),
          ),
      ],
    );
  }
}

