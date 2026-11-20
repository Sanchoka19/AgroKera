import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'onboarding_page_indicator.dart';

/// Bottom action controls with:
/// - Previous arrow on far left (or matching spacer on page 0 for perfect centering)
/// - Page indicator dots dead-centered
/// - Next arrow on far right
/// - Step 3 (Final): Full-width start button + login link
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
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: !isLastPage
            // Step 1 & 2 Layout: Left Arrow, Centered Dots, Right Arrow
            ? Row(
                key: const ValueKey('step_controls'),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Far Left: Previous Arrow Button (or 54px placeholder when on slide 0)
                  if (currentIndex > 0)
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: IconButton(
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
                          shape: const CircleBorder(),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 54, height: 54),

                  // Center: Page Indicator Dots
                  OnboardingPageIndicator(
                    count: totalPages,
                    currentIndex: currentIndex,
                  ),

                  // Far Right: Next Arrow Button
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: ElevatedButton(
                      key: const Key('onboarding_next_button'),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
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
