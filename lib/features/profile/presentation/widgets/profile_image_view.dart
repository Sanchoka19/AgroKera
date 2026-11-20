import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

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
      placeholder: defaultFallbackUrl.startsWith('assets/')
          ? Image.asset(
              defaultFallbackUrl,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primaryLight,
                width: width,
                height: height,
              ),
            )
          : Image.network(
              defaultFallbackUrl,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primaryLight,
                width: width,
                height: height,
              ),
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
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _defaultFallback();
    }

    // 0. Asset image
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _defaultFallback(),
      );
    }

    // 1. Network image
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _defaultFallback(),
      );
    }

    // 2. Data URL (Base64)
    if (url.startsWith('data:image/')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _defaultFallback(),
        );
      } catch (_) {
        return _defaultFallback();
      }
    }

    // 3. Local file on device
    if (!kIsWeb) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _defaultFallback(),
          );
        }
      } catch (_) {
        return _defaultFallback();
      }
    }

    return _defaultFallback();
  }
}
