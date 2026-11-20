import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/onboarding_item.dart';

/// Single slide presentation widget displaying the vector illustration, badge, title, and description.
class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlideWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final illustrationHeight = (size.height * 0.36).clamp(220.0, 320.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // SVG Vector Illustration
          SizedBox(
            height: illustrationHeight,
            width: double.infinity,
            child: SvgPicture.asset(
              item.illustrationAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 28),

          // Subtitle Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.subtitle,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Main Title
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

