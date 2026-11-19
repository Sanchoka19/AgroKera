import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';

/// Pure presentation widget for the centered AgroKera brand logo lockup.
/// Built specifically for high-contrast presentation on green surfaces.
class SplashLogoBadge extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showSubtitle;
  final String? subtitleText;

  const SplashLogoBadge({
    super.key,
    this.iconSize = 64,
    this.fontSize = 22,
    this.showSubtitle = true,
    this.subtitleText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          AppAssets.logoWhite,
          width: iconSize,
          height: iconSize,
          placeholderBuilder: (context) => Icon(
            LucideIcons.sprout,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'AGROKERA',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3.0,
            height: 1.1,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            subtitleText ?? 'ნატურალური & ქართული',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
