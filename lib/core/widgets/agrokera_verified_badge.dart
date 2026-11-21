import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_assets.dart';

/// Authentic AgroKera SVG Verified Badge:
/// Features the brand's teal rosette seal, leaf checkmark, and lime sprout bud.
class AgroKeraVerifiedBadge extends StatelessWidget {
  final double size;
  final bool showLabel;
  final String tooltip;

  const AgroKeraVerifiedBadge({
    super.key,
    this.size = 16.0,
    this.showLabel = false,
    this.tooltip = 'ვერიფიცირებული ფერმერი',
  });

  @override
  Widget build(BuildContext context) {
    final badge = Tooltip(
      message: tooltip,
      child: SvgPicture.asset(
        AppAssets.verifiedBadge,
        width: size,
        height: size,
      ),
    );

    if (!showLabel) return badge;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(width: 5),
          Text(
            'ვერიფიცირებული',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}
