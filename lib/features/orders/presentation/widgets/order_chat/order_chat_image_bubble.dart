import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_cached_image.dart';
import '../../../../profile/presentation/widgets/profile_image_view.dart';
import '../../../domain/models/order_message_model.dart';

/// Renders photo / image attachments sent within the Order Chat.
///
/// Features:
/// * Clean rounded card with aspect-ratio containment.
/// * Support for local files, data URIs, and remote HTTPS URLs.
/// * Optional caption text below the image.
/// * 1-Tap Full Screen viewer dialog.
/// * Zero emojis, strictly using Lucide icons.
class OrderChatImageBubble extends StatelessWidget {
  final OrderMessage message;
  final bool isMe;
  final String? partnerAvatarUrl;

  const OrderChatImageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.partnerAvatarUrl,
  });

  void _openFullScreenViewer(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => _FullScreenImageViewerDialog(
        imageUrl: imageUrl,
        caption: message.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    final imageUrl = message.imageUrl?.trim() ?? '';
    final hasCaption = message.text.trim().isNotEmpty;

    final bubbleCard = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.74,
      ),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Incoming sender name header
          if (!isMe) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 10, right: 12),
              child: Text(
                message.senderName,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Image Container
          Padding(
            padding: const EdgeInsets.all(4),
            child: GestureDetector(
              onTap: imageUrl.isNotEmpty
                  ? () => _openFullScreenViewer(context, imageUrl)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 240,
                        minHeight: 140,
                        minWidth: 180,
                      ),
                      color: const Color(0xFFF1F5F9),
                      child: _buildImage(imageUrl),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.maximize2,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Caption (if any)
          if (hasCaption) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                message.text,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : const Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
            ),
          ],

          // Time Stamp
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8, top: 2),
            child: Text(
              timeStr,
              style: GoogleFonts.firaCode(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.72)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: bubbleCard,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ProfileImageView.avatar(
              avatarUrl: partnerAvatarUrl,
              size: 28,
            ),
            const SizedBox(width: 8),
            Flexible(child: bubbleCard),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return const Center(
        child: Icon(LucideIcons.image, size: 28, color: Color(0xFF94A3B8)),
      );
    }

    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final b64 = url.substring(commaIdx + 1);
          final bytes = base64Decode(b64);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
          );
        }
      } catch (_) {}
    }

    if (!kIsWeb && (url.startsWith('/') || url.startsWith('file://'))) {
      final cleanPath = url.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, error, stackTrace) => const Center(
          child: Icon(LucideIcons.imageOff, size: 24, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return AppCachedImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      fallbackIcon: LucideIcons.imageOff,
    );
  }
}

class _FullScreenImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String caption;

  const _FullScreenImageViewerDialog({
    required this.imageUrl,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 26),
              splashRadius: 22,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: _buildImageWidget(imageUrl),
              ),
            ),
          ),
          if (caption.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                caption.trim(),
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(url.substring(commaIdx + 1));
          return Image.memory(bytes, fit: BoxFit.contain);
        }
      } catch (_) {}
    }

    if (!kIsWeb && (url.startsWith('/') || url.startsWith('file://'))) {
      final cleanPath = url.replaceFirst('file://', '');
      return Image.file(File(cleanPath), fit: BoxFit.contain);
    }

    return AppCachedImage(
      imageUrl: url,
      fit: BoxFit.contain,
      fallbackIcon: LucideIcons.imageOff,
    );
  }
}
