import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/constants/app_assets.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/marketplace/presentation/screens/farmer_profile_screen.dart';

/// Interactive Farmer Profile Mini-Card with verified badge, location, and rating.
class ProductFarmerCard extends StatelessWidget {
  final FarmerModel farmer;

  const ProductFarmerCard({super.key, required this.farmer});

  Widget _buildAvatar(String avatarUrl) {
    Widget fallback() => Container(
          width: 48,
          height: 48,
          color: const Color(0xFFE8F7EE),
          child: const Icon(
            LucideIcons.user,
            color: AppColors.primary,
          ),
        );

    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return Image.network(
        avatarUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    if (avatarUrl.startsWith('data:image/')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(avatarUrl).existsSync()) {
      return Image.file(
        File(avatarUrl),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return fallback();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FarmerProfileScreen(farmer: farmer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Farmer Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildAvatar(farmer.avatarUrl),
              ),
              const SizedBox(width: 12),

              // Farm Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            farmer.farmName,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (farmer.isVerified) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'ვერიფიცირებული ფერმერი',
                            child: SvgPicture.asset(
                              AppAssets.verifiedBadge,
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            farmer.location,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.rating,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${farmer.rating} (${farmer.reviewCount})',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Navigation Arrow
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
