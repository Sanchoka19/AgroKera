import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_cached_image.dart';

/// Reusable, robust image viewer for Profile Avatars and Farm Cover Banners.
///
/// Seamlessly handles:
/// * Local asset images (assets/...)
/// * Remote HTTP/HTTPS URLs
/// * Local device files (from ImagePicker)
/// * Inline data URLs (data:image/...)
/// * Graceful fallbacks and placeholders on error or null
class ProfileImageView extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;

  const ProfileImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
  });

  /// Factory constructor specifically tailored for circular or square avatars
  factory ProfileImageView.avatar({
    Key? key,
    required String? avatarUrl,
    double size = 42,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return ProfileImageView(
      key: key,
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      width: size,
      height: size,
      placeholder: Container(
        width: size,
        height: size,
        color: backgroundColor ?? AppColors.primaryLight,
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.user,
          size: size * 0.52,
          color: iconColor ?? AppColors.primary,
        ),
      ),
    );
  }

  /// Factory constructor specifically tailored for farm hero & card cover banners
  factory ProfileImageView.cover({
    Key? key,
    required String? coverUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    String defaultFallbackUrl = AppAssets.defaultFarmCover,
  }) {
    final effectiveUrl = (coverUrl != null && coverUrl.trim().isNotEmpty)
        ? coverUrl.trim()
        : defaultFallbackUrl;

    return ProfileImageView(
      key: key,
      imageUrl: effectiveUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: AppCachedImage(
        imageUrl: defaultFallbackUrl,
        fit: fit,
        width: width,
        height: height,
        fallbackIcon: LucideIcons.image,
      ),
    );
  }

  Widget _defaultFallback() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: AppColors.primaryLight,
          alignment: Alignment.center,
          child: const Icon(LucideIcons.image, color: AppColors.primary),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fallback: _defaultFallback(),
      placeholder: placeholder,
    );
  }
}
