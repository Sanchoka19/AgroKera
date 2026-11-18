import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Customer profile header with avatar, name, email, and camera button
class CustomerProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String userName;
  final String userEmail;
  final VoidCallback onAvatarTap;
  final VoidCallback? onEditTap;

  const CustomerProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.userName,
    required this.userEmail,
    required this.onAvatarTap,
    this.onEditTap,
  });

  Widget _buildAvatarImage(String? url, [double size = 42]) {
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: Icon(LucideIcons.user, size: size, color: AppColors.primary),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.primaryLight,
          alignment: Alignment.center,
          child: Icon(LucideIcons.user, size: size, color: AppColors.primary),
        ),
      );
    }
    if (!kIsWeb && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.primaryLight,
          alignment: Alignment.center,
          child: Icon(LucideIcons.user, size: size, color: AppColors.primary),
        ),
      );
    }
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Icon(LucideIcons.user, size: size, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(avatarUrl, 42),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onEditTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEditTap != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.pencil,
                      size: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              userEmail,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

