import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';

/// Guest Promo Banner displayed across Home & Profile screens
/// Exact visual match to Figma screenshots using official SVG illustration:
/// - Official require_signin.svg illustration
/// - Title: "არ გაქვს ანგარიში?"
/// - Subtitle: "აპლიკაციის ფუნქციონალით სრულყოფილად სარგებლობისთვის გაიარე რეგისტრაცია"
/// - Green CTA links: "ავტორიზაცია | რეგისტრაცია"
/// - Dismissible with 'X' button
class GuestPromoBanner extends ConsumerStatefulWidget {
  final bool showCloseButton;

  const GuestPromoBanner({super.key, this.showCloseButton = true});

  @override
  ConsumerState<GuestPromoBanner> createState() => _GuestPromoBannerState();
}

class _GuestPromoBannerState extends ConsumerState<GuestPromoBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Stack(
        children: [
          if (widget.showCloseButton)
            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: () => setState(() => _isDismissed = true),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              // Official SVG Illustration
              SizedBox(
                width: 80,
                height: 80,
                child: SvgPicture.asset(
                  AppAssets.requireSignIn,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'არ გაქვს ანგარიში?',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'აპლიკაციის ფუნქციონალით\nსრულყოფილად სარგებლობისთვის\nგაიარე რეგისტრაცია',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Action links row: "ავტორიზაცია | რეგისტრაცია"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => AuthRequiredBottomSheet.show(context),
                    child: Text(
                      'ავტორიზაცია',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 14,
                    width: 1,
                    color: AppColors.border,
                  ),
                  GestureDetector(
                    onTap: () => AuthRequiredBottomSheet.show(context),
                    child: Text(
                      'რეგისტრაცია',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
