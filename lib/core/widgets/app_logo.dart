import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Authentic AgroKera brand logo based on Figma screenshots:
/// Official SVG sprout emblem + "აგრო" (#181725) + "კერა" (#53B175)
/// Rendered with genuine Noto Sans Georgian Black (Weight 900) for maximum punchy boldness.
class AppLogo extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const AppLogo({super.key, this.fontSize = 26, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          AppAssets.logoGreen,
          width: iconSize,
          height: iconSize,
          placeholderBuilder: (context) => Icon(
            LucideIcons.sprout,
            size: iconSize,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'აგრო',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.30),
                      blurRadius: 0.8,
                      offset: const Offset(0.4, 0.4),
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'კერა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 0.8,
                      offset: const Offset(0.4, 0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
