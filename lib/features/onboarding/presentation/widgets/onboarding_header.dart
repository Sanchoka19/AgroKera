import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Top bar widget with AgroKera brand logo/name on the left and skip action on the right.
class OnboardingHeader extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onSkip;

  const OnboardingHeader({
    super.key,
    required this.isLastPage,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Lockup (Logo + Title)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.logoGreen,
                width: 24,
                height: 24,
                placeholderBuilder: (_) => const Icon(
                  LucideIcons.sprout,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AGROKERA',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),

          // Skip Action
          AnimatedOpacity(
            opacity: isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: isLastPage,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onSkip();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'გამოტოვება',
                  style: AppTypography.caption.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
