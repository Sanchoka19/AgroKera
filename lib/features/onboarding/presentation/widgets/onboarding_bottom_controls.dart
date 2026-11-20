import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'onboarding_page_indicator.dart';

/// Bottom action controls featuring a modern arrow-button layout and animated indicator.
class OnboardingBottomControls extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onFinish;
  final VoidCallback onSignIn;

  const OnboardingBottomControls({
    super.key,
    required this.currentIndex,
    required this.totalPages,
    required this.isLastPage,
    required this.onNext,
    required this.onPrevious,
    required this.onFinish,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: !isLastPage
            // Step 1 & 2 Layout: Indicator on Left, Arrow Controls on Right
            ? Row(
                key: const ValueKey('step_controls'),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OnboardingPageIndicator(
                    count: totalPages,
                    currentIndex: currentIndex,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentIndex > 0) ...[
                        IconButton(
                          key: const Key('onboarding_prev_button'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onPrevious();
                          },
                          icon: const Icon(
                            LucideIcons.arrowLeft,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      ElevatedButton(
                        key: const Key('onboarding_next_button'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onNext();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          elevation: 2,
                          shadowColor:
                              AppColors.primary.withValues(alpha: 0.3),
                        ),
                        child: const Icon(
                          LucideIcons.arrowRight,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            // Step 3 (Final) Layout: Full-Width Start Button with Arrow + Login Link
            : Column(
                key: const ValueKey('finish_controls'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('onboarding_start_button'),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onFinish();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor:
                            AppColors.primary.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'დაწყება',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.arrowRight,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onSignIn();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'უკვე გაქვთ ანგარიში? შესვლა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
