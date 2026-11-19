import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// Presentation widget displaying authentication action buttons.
/// Slides down into view at the top of the screen when unauthenticated.
class SplashAuthContent extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onContinueAsGuest;

  const SplashAuthContent({
    super.key,
    required this.onGoogleSignIn,
    required this.onSignIn,
    required this.onSignUp,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Google Sign-In Button
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onGoogleSignIn();
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.google,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Google-ით შესვლა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Standard Sign In & Sign Up Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onSignIn();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'შესვლა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onSignUp();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'რეგისტრაცია',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Continue as Guest button
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onContinueAsGuest();
            },
            child: Text(
              'სტუმრად დათვალიერება',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
