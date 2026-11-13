import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Authentic AgroKera brand logo based on Figma screenshots:
/// Official SVG sprout emblem + "აგრო" (#181725) + "კერა" (#53B175)
class AppLogo extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const AppLogo({super.key, this.fontSize = 22, this.iconSize = 28});

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
                style: AppTypography.h1.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'კერა',
                style: AppTypography.h1.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
