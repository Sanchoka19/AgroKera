import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';

/// Centralized, high-performance image rendering component.
///
/// Features:
/// 1. Offline disk & memory caching via [CachedNetworkImage]
/// 2. Automatic resolution of assets, base64 data URLs, local files and network URLs
/// 3. Non-blocking UI thread execution (no synchronous File I/O on network URLs)
/// 4. Shimmer/skeleton placeholders and clean vector fallback icons (no emojis)
/// 5. Graceful offline fallback in test environments
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? fallback;
  final IconData fallbackIcon;
  final double? iconSize;
  final Color? backgroundColor;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.fallback,
    this.fallbackIcon = LucideIcons.image,
    this.iconSize,
    this.backgroundColor,
  });

  Widget _defaultFallback() {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.surfaceInput,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: AppColors.textSecondary,
        size: iconSize ?? (width != null ? (width! * 0.4).clamp(16.0, 36.0) : 24.0),
      ),
    );
  }

  Widget _defaultPlaceholder() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.surfaceInput,
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _wrapRadius(_defaultFallback());
    }

    // 1. Flutter local asset bundle
    if (url.startsWith('assets/')) {
      return _wrapRadius(
        Image.asset(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _defaultFallback(),
        ),
      );
    }

    // 2. Base64 Data URL
    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str);
        return _wrapRadius(
          Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _defaultFallback(),
          ),
        );
      } catch (_) {
        return _wrapRadius(_defaultFallback());
      }
    }

    // 3. Network URL (HTTP/HTTPS) -> CachedNetworkImage
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (isFlutterTestEnv) {
        return _wrapRadius(
          Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _defaultFallback(),
          ),
        );
      }

      return _wrapRadius(
        CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, _) => _defaultPlaceholder(),
          errorWidget: (_, _, _) => _defaultFallback(),
        ),
      );
    }

    // 4. Local File path
    if (!kIsWeb) {
      try {
        final cleanPath = url.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (file.existsSync()) {
          return _wrapRadius(
            Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => _defaultFallback(),
            ),
          );
        }
      } catch (_) {}
    }

    return _wrapRadius(_defaultFallback());
  }

  Widget _wrapRadius(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}

