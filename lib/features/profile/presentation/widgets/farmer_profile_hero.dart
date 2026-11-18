import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../orders/presentation/providers/order_chat_provider.dart';
import '../../../orders/presentation/screens/order_chats_list_screen.dart';
import 'avatar_picker_modal.dart';
import 'cover_photo_picker_modal.dart';
import 'edit_profile_bottom_sheet.dart';

/// Parallax hero header for Farmer profile with cover, frosted action icons and farm card.
class FarmerProfileHero extends ConsumerWidget {
  final AuthState authState;
  final double scrollOffset;

  const FarmerProfileHero({
    super.key,
    required this.authState,
    required this.scrollOffset,
  });

  Widget _buildCoverImage(String? coverUrl) {
    final url = (coverUrl != null && coverUrl.isNotEmpty)
        ? coverUrl
        : 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1000&auto=format&fit=crop&q=80';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.primaryLight),
      );
    }
    if (url.startsWith('data:image/')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: AppColors.primaryLight),
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.primaryLight),
      );
    }
    return Container(color: AppColors.primaryLight);
  }

  Widget _buildAvatarImage(String? avatarUrl, [double size = 42]) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildPlaceholderAvatar(size);
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderAvatar(size),
      );
    }
    if (avatarUrl.startsWith('data:image/')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderAvatar(size),
        );
      } catch (_) {}
    }
    if (!kIsWeb && File(avatarUrl).existsSync()) {
      return Image.file(
        File(avatarUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderAvatar(size),
      );
    }
    return _buildPlaceholderAvatar(size);
  }

  Widget _buildPlaceholderAvatar([double size = 42]) {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.user,
        size: size,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    String? badgeText,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: const Color(0xFF0F172A),
                    ),
                    if (badgeText != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketplace = ref.watch(marketplaceProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final unreadChats = ref.watch(unreadChatCountProvider);
    final topInset = MediaQuery.of(context).padding.top;
    final coverHeight = 185.0 + topInset;
    final heroHeight = coverHeight + 58.0;

    final matchedFarmer = marketplace.farmers.where(
      (f) =>
          (authState.farmerId != null && f.id == authState.farmerId) ||
          (authState.farmName != null && f.farmName == authState.farmName),
    ).firstOrNull;
    final farmerAvatar = authState.userAvatarUrl ?? matchedFarmer?.avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: heroHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Cover Photo Container with Parallax & Stretch Zoom
              Positioned(
                top: scrollOffset < 0 ? scrollOffset : 0,
                left: 0,
                right: 0,
                height: scrollOffset < 0
                    ? coverHeight + (-scrollOffset)
                    : coverHeight,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.translate(
                        offset: Offset(
                          0,
                          scrollOffset > 0 ? scrollOffset * 0.45 : 0,
                        ),
                        child: Transform.scale(
                          scale: scrollOffset < 0
                              ? 1.0 + (-scrollOffset / 320)
                              : 1.0,
                          alignment: Alignment.topCenter,
                          child: _buildCoverImage(
                            authState.farmCoverUrl ?? matchedFarmer?.coverUrl,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.35, 0.65, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.50),
                            ],
                          ),
                        ),
                      ),

                      // Top-Right: Floating Frosted Action Buttons (Chat & Notifications)
                      Positioned(
                        top: topInset + 8,
                        right: 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFrostedCircleButton(
                              context: context,
                              icon: LucideIcons.messageSquare,
                              tooltip: 'შეკვეთის ჩათი',
                              badgeText: (authState.isAuthenticated &&
                                      unreadChats > 0)
                                  ? (unreadChats > 9 ? '9+' : '$unreadChats')
                                  : null,
                              onTap: () {
                                requireAuth(
                                  context,
                                  ref: ref,
                                  onAuthenticated: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OrderChatsListScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildFrostedCircleButton(
                              context: context,
                              icon: LucideIcons.bell,
                              tooltip: 'შეტყობინებები',
                              badgeText: (authState.isAuthenticated &&
                                      unreadNotifs > 0)
                                  ? (unreadNotifs > 9 ? '9+' : '$unreadNotifs')
                                  : null,
                              onTap: () {
                                requireAuth(
                                  context,
                                  ref: ref,
                                  onAuthenticated: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Top-Left: Change Cover Photo Button
                      Positioned(
                        top: topInset + 8,
                        left: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => CoverPhotoPickerModal.show(context),
                            borderRadius: BorderRadius.circular(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.camera,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'შეცვლა',
                                        style: GoogleFonts.notoSansGeorgian(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Overlapping Farmer Profile Card
              Positioned(
                bottom: 0,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border:
                        Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Farmer Avatar with Camera Badge
                      GestureDetector(
                        onTap: () => AvatarPickerModal.show(context, ref),
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _buildAvatarImage(farmerAvatar, 30),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.camera,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Farmer Name and Farm Name
                      Expanded(
                        child: InkWell(
                          onTap: () => EditProfileBottomSheet.show(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        authState.userName ?? 'რევაზ ბერიძე',
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: 'ვერიფიცირებული ფერმერი',
                                      child: SvgPicture.asset(
                                        AppAssets.verifiedBadge,
                                        width: 18,
                                        height: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.sprout,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        (authState.farmName != null &&
                                                authState
                                                    .farmName!.trim().isNotEmpty)
                                            ? authState.farmName!
                                            : 'ჩემი მეურნეობა',
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 13,
                                          color: const Color(0xFF475569),
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Edit Profile Button
                      Material(
                        color: Colors.transparent,
                        child: Tooltip(
                          message: 'პროფილის რედაქტირება',
                          child: InkWell(
                            onTap: () => EditProfileBottomSheet.show(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.pencil,
                                size: 14,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

