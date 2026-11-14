import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Authentic AgroKera brand logo:
/// Official SVG sprout emblem + uppercase "AGRO" (#181725) + "KERA" (#0F766E)
/// Vertically centered on one crisp horizontal optical baseline.
class AppLogo extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const AppLogo({super.key, this.fontSize = 20, this.iconSize = 30});

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
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'AGRO',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 2.2,
                height: 1.0,
              ),
            ),
            Text(
              'KERA',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2.2,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
