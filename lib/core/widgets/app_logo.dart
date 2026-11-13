import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Authentic AgroKera brand logo based on Figma screenshots:
/// Green sprout icon + "აგრო" (#181725) + "კერა" (#53B175)
class AppLogo extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const AppLogo({super.key, this.fontSize = 22, this.iconSize = 26});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize + 6,
          height: iconSize + 6,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.sprout,
            size: iconSize - 2,
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
