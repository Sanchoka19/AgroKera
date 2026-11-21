import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/onboarding_item.dart';

/// Single slide presentation widget displaying the vector illustration, badge, title, and description.
/// Uses [AutomaticKeepAliveClientMixin] to prevent rebuilding or re-parsing SVGs when swiping.
class OnboardingSlideWidget extends StatefulWidget {
  final OnboardingItem item;

  const OnboardingSlideWidget({
    super.key,
    required this.item,
  });

  @override
  State<OnboardingSlideWidget> createState() => _OnboardingSlideWidgetState();
}

class _OnboardingSlideWidgetState extends State<OnboardingSlideWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.sizeOf(context);
    final illustrationHeight = (size.height * 0.36).clamp(220.0, 320.0);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
              widget.item.illustrationAsset,
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
              widget.item.subtitle,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Main Title
          Text(
            widget.item.title,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            widget.item.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
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
