import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/constants/app_assets.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_confirmation_bottom_sheet.dart';
import 'package:agrokera/core/widgets/app_header.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/farm_inventory/presentation/screens/farmer_inventory_screen.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/models/farmer_onboarding_state.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'package:agrokera/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:agrokera/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:agrokera/features/orders/presentation/screens/client_orders_screen.dart';
import 'package:agrokera/features/orders/presentation/screens/incoming_orders_screen.dart';
import 'farmer_delivery_settings_screen.dart';
import 'help_center_screen.dart';

class GuestProfileScreen extends ConsumerStatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  ConsumerState<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends ConsumerState<GuestProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkThemeEnabled = false;
  String _selectedLanguage = 'KA'; // 'KA' or 'EN'

  String _detectedAddress = 'ჭავჭავაძე - თბილისი';

  Future<void> _detectUserAddressWithGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (!mounted) return;
          AppToast.error(
            context,
            'მდებარეობაზე წვდომის ნებართვა უარყოფილია',
          );
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        AppToast.error(
          context,
          'მდებარეობის ნებართვა დაბლოკილია პარამეტრებიდან',
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final resolved = GeorgianGeoLookup.resolveInstantAddress(
        LatLng(pos.latitude, pos.longitude),
      );
      setState(() => _detectedAddress = resolved);
      AppToast.success(context, 'თქვენი მისამართი განახლდა: $resolved');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'GPS მდებარეობის დადგენა ვერ მოხერხდა. შეამოწმეთ ნებართვა.',
      );
    }
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

  void _showAvatarPickerModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'პროფილის ფოტოს შეცვლა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'აირჩიეთ ფოტოს წყარო პროფილის განახლებისთვის',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    'კამერით გადაღება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'გადაიღე ახალი ფოტო კამერით',
                    style: GoogleFonts.notoSansGeorgian(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadAvatar(ImageSource.camera);
                  },
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: Color(0xFF3B82F6), size: 20),
                  ),
                  title: Text(
                    'გალერეიდან არჩევა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'აირჩიე სურათი ტელეფონის მეხსიერებიდან',
                    style: GoogleFonts.notoSansGeorgian(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadAvatar(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (file == null || !mounted) return;

      AppToast.info(context, 'პროფილის ფოტო იტვირთება...');

      final success = await ref.read(authStateProvider.notifier).uploadAvatar(file);
      unawaited(ref.read(marketplaceProvider.notifier).refreshFromBackend());

      if (mounted) {
        if (success) {
          AppToast.success(context, 'პროფილის ფოტო წარმატებით განახლდა!');
        } else {
          AppToast.success(context, 'პროფილის ფოტო შენახულია');
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'ფოტოს არჩევა ვერ მოხერხდა');
      }
    }
  }

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

  void _showCoverPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ფერმის გარეკანის შეცვლა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ეს ფოტო გამოჩნდება თქვენს პროფილზე და მთავარ გვერდზე',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                  title: Text(
                    'კამერით გადაღება',
                    style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('გადაუღე ფერმას ან მეურნეობას'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? file = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );
                      if (!mounted) return;
                      if (file != null) {
                        AppToast.info(context, 'გარეკანის ფოტო იტვირთება...');
                        await ref
                            .read(authStateProvider.notifier)
                            .uploadFarmCover(file);
                        unawaited(ref
                            .read(marketplaceProvider.notifier)
                            .refreshFromBackend());
                        if (mounted) {
                          AppToast.success(context, 'გარეკანის ფოტო წარმატებით განახლდა!');
                        }
                      }
                    } catch (_) {
                      if (!mounted) return;
                      AppToast.error(context, 'კამერის გახსნა ვერ მოხერხდა');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image, color: AppColors.primary),
                  title: Text(
                    'გალერეიდან არჩევა',
                    style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('ატვირთე ლანდშაფტური სურათი'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (!mounted) return;
                      if (file != null) {
                        AppToast.info(context, 'გარეკანის ფოტო იტვირთება...');
                        await ref
                            .read(authStateProvider.notifier)
                            .uploadFarmCover(file);
                        unawaited(ref
                            .read(marketplaceProvider.notifier)
                            .refreshFromBackend());
                        if (mounted) {
                          AppToast.success(context, 'გარეკანის ფოტო წარმატებით განახლდა!');
                        }
                      }
                    } catch (_) {
                      if (!mounted) return;
                      AppToast.error(context, 'ფოტოს არჩევა ვერ მოხერხდა');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.sparkles, color: AppColors.primary),
                  title: Text(
                    'სანიმუშო აგრო-გარეკანის არჩევა',
                    style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('მზა თემატური ფოტოები (ვენახი, ბაღი, სათბური)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetCoverPicker();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPresetCoverPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'აირჩიე სანიმუშო გარეკანი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: FarmerOnboardingState.presetFarmCovers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final preset = FarmerOnboardingState.presetFarmCovers[index];
                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await ref
                              .read(authStateProvider.notifier)
                              .updateFarmCoverUrl(preset['url']!);
                          unawaited(ref
                              .read(marketplaceProvider.notifier)
                              .refreshFromBackend());
                          if (!mounted) return;
                          if (context.mounted) {
                            AppToast.success(
                                context, 'გარეკანი არჩეულია: ${preset["title"]}');
                          }
                        },
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                preset['url']!,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.70),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  preset['title']!,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isFarmer = authState.role == UserRole.farmer;
    final isGuest = !authState.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: !isFarmer, // Farmer cover photo extends edge-to-edge behind status bar
        child: Column(
          children: [
            // Standard App Header for Customer & Guest (Farmer uses edge-to-edge cover with floating frosted actions)
            if (!isFarmer)
              AppHeader(
                title: 'ჩემი პროფილი',
                showNotificationBell: true,
                showCart: false,
                actions: [
                  IconButton(
                    tooltip: 'შეკვეთის ჩათი',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      requireAuth(
                        context,
                        ref: ref,
                        onAuthenticated: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ClientOrdersScreen(),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      LucideIcons.messageSquare,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isFarmer ? 0 : 20,
                  isFarmer ? 0 : 4,
                  isFarmer ? 0 : 20,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // GUEST: Official Previous Version Illustration Promo Banner
                    // AUTHENTICATED: Modern Hero Avatar + Gradient KPI Card
                    // ==========================================
                    if (isGuest) ...[
                      const GuestPromoBanner(showCloseButton: false),
                      const SizedBox(height: 24),
                    ] else if (isFarmer) ...[
                      // ONLY for Farmer: Edge-to-edge cover photo touching header,
                      // and half-overlapping profile card with full farm name
                      _buildFarmerProfileHero(authState),
                    ] else ...[
                      // Regular Customer Hero Identity
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _showAvatarPickerModal,
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
                                      child: _buildAvatarImage(authState.userAvatarUrl, 42),
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
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                authState.userName ?? 'საბა ევგენიძე',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                authState.userEmail ?? 'sabaevgenidze0919@gmail.com',
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
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Lower profile content with horizontal padding for Farmer
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isFarmer ? 20 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Emerald Gradient KPI Hero Card & Verified Badge (ONLY for Farmer)
                          if (isFarmer) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: const RadialGradient(
                                  center: Alignment(-0.85, -0.75),
                                  radius: 1.35,
                                  colors: [
                                    Color(0xFF059669), // Vibrant Radiant Emerald around trophy
                                    Color(0xFF0D7A68), // Rich Teal
                                    Color(0xFF044E46), // Deep Forest Teal at bottom-right
                                  ],
                                  stops: [0.0, 0.45, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF044E46).withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.trophy,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'საფერმო მაჩვენებლები და KPI',
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildGradientMetricCol(
                                          value: '5000₾',
                                          label: 'ჯამური შემოსავალი',
                                        ),
                                      ),
                                      Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.22)),
                                      Expanded(
                                        child: _buildGradientMetricCol(
                                          value: '100',
                                          label: 'შეკვეთების რაოდენობა',
                                        ),
                                      ),
                                      Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.22)),
                                      Expanded(
                                        child: _buildGradientMetricCol(
                                          value: '4.5',
                                          label: 'საშუალო შეფასება',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

              // ==========================================
              // 4. GROUPED SECTION 1: საფერმო საქმიანობა & პირადი შესყიდვები / ინსტრუმენტები
              // (Clean White Card, NO Harsh Black Borders!)
              // ==========================================
              if (isFarmer) ...[
                _buildSectionHeader('საფერმო საქმიანობა'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileRowItem(
                        icon: LucideIcons.shoppingBag,
                        title: 'ჩემი პროდუქტები',
                        subtitle: 'პროდუქტების სია და ფასები',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FarmerInventoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.clipboardCheck,
                        title: 'შემოსული შეკვეთები',
                        subtitle: 'შეკვეთების მართვა და სტატუსი',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const IncomingOrdersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.truck,
                        title: 'მიწოდების პარამეტრები',
                        subtitle: 'მიტანის ზონები, ტარიფები და გრაფიკი',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FarmerDeliverySettingsScreen(
                                    farmerId: authState.farmerId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.mapPin,
                        title: 'ჩემი მისამართი',
                        subtitle: 'ფერმის ლოკაციის GPS-ით განახლება ($_detectedAddress)',
                        onTap: _detectUserAddressWithGps,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('პირადი შესყიდვები'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileRowItem(
                        icon: LucideIcons.shoppingBag,
                        title: 'ჩემი შეკვეთები',
                        subtitle: 'შეკვეთების ისტორია და სტატუსი',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ClientOrdersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.heart,
                        title: 'ფავორიტები',
                        subtitle: 'შენახული სასურველი პროდუქტები',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                _buildSectionHeader('ინსტრუმენტები და სერვისები'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileRowItem(
                        icon: LucideIcons.shoppingBag,
                        title: 'ჩემი შეკვეთები',
                        subtitle: 'შეკვეთების ისტორია და სტატუსი',
                        onTap: () {
                          requireAuth(
                            context,
                            ref: ref,
                            onAuthenticated: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ClientOrdersScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.heart,
                        title: 'ფავორიტები',
                        subtitle: 'შენახული სასურველი პროდუქტები',
                        onTap: () {
                          requireAuth(
                            context,
                            ref: ref,
                            onAuthenticated: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.mapPin,
                        title: 'ჩემი მისამართი',
                        subtitle: 'GPS-ით დადგენა ($_detectedAddress)',
                        onTap: () {
                          requireAuth(
                            context,
                            ref: ref,
                            onAuthenticated: _detectUserAddressWithGps,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 24),

              // ==========================================
              // 5. GROUPED SECTION 2: პარამეტრები
              // (Dark Theme Switch, Language Segmented Toggle, Notifications)
              // ==========================================
              _buildSectionHeader('პარამეტრები'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dark theme toggle switch
                    _buildProfileRowItem(
                      icon: LucideIcons.sun,
                      title: 'მუქი თემა',
                      subtitle: 'ღამის რეჟიმის ჩართვა/გამორთვა',
                      trailing: Switch.adaptive(
                        value: _darkThemeEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _darkThemeEnabled = val);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _darkThemeEnabled = !_darkThemeEnabled);
                      },
                    ),
                    _buildRowDivider(),

                    // Language Segmented Pill Toggle: [ KA | EN ]
                    _buildProfileRowItem(
                      icon: LucideIcons.globe,
                      title: 'აპლიკაციის ენა',
                      subtitle: 'ინტერფეისის ენის არჩევა',
                      trailing: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLanguagePill('KA', _selectedLanguage == 'KA'),
                            _buildLanguagePill('EN', _selectedLanguage == 'EN'),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLanguage = _selectedLanguage == 'KA' ? 'EN' : 'KA';
                        });
                      },
                    ),
                    _buildRowDivider(),

                    // Notifications switch
                    _buildProfileRowItem(
                      icon: LucideIcons.bell,
                      title: 'შეტყობინებები',
                      subtitle: 'შეტყობინებების მიღება და სიახლეები',
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _notificationsEnabled = val);
                        },
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _notificationsEnabled = !_notificationsEnabled);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 6. GROUPED SECTION 3: დახმარება და მხარდაჭერა / Logout
              // ==========================================
              _buildSectionHeader('დახმარება და მხარდაჭერა'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileRowItem(
                      icon: LucideIcons.helpCircle,
                      title: 'დახმარების ცენტრი',
                      subtitle: 'ინსტრუქციები, FAQ და მხარდაჭერა',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    if (!isGuest) ...[
                      _buildRowDivider(),
                      _buildProfileRowItem(
                        icon: LucideIcons.logOut,
                        iconColor: const Color(0xFFEF4444),
                        tileColor: const Color(0xFFFEF2F2),
                        title: 'გამოსვლა',
                        subtitle: 'ანგარიშიდან გამოსვლა',
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final confirmed = await AppConfirmationBottomSheet.showLogout(
                            context: context,
                          );
                          if (confirmed) {
                            ref.read(authStateProvider.notifier).logout();
                            if (context.mounted) {
                              AppToast.info(context, 'თქვენ გამოხვედით ანგარიშიდან');
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // App Version Footer
              Center(
                child: Text(
                  'აგროკერა • ვერსია 1.0.0',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header Text
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.notoSansGeorgian(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Row Item with Squircle Tile
  Widget _buildProfileRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = AppColors.primary,
    Color tileColor = AppColors.primaryLight,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Pastel Squircle Icon Tile
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Title and Descriptive Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing action or subtle chevron
              trailing ??
                  const Icon(
                    LucideIcons.chevronRight,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDivider() {
    return const Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  // Metric column inside the emerald gradient KPI card
  Widget _buildGradientMetricCol({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagePill(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedLanguage = text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedCircleButton({
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
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                      color: Colors.white,
                    ),
                    if (badgeText != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 15,
                            minHeight: 15,
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

  Widget _buildFarmerProfileHero(AuthState authState) {
    final marketplace = ref.watch(marketplaceProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
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
              // 1. Cover Photo Container (Full-width, touches edges and top status bar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverImage(authState.farmCoverUrl ?? matchedFarmer?.coverUrl),
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
                            icon: LucideIcons.messageSquare,
                            tooltip: 'შეკვეთის ჩათი',
                            onTap: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const IncomingOrdersScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildFrostedCircleButton(
                            icon: LucideIcons.bell,
                            tooltip: 'შეტყობინებები',
                            badgeText: (authState.isAuthenticated && unreadNotifs > 0)
                                ? (unreadNotifs > 9 ? '9+' : '$unreadNotifs')
                                : null,
                            onTap: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Bottom-Right: Change Cover Photo Button
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showCoverPhotoPicker,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
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
                  ],
                ),
              ),

              // 2. Overlapping Farmer Profile Card: sits inside heroHeight bounds (hit test safe)
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
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Farmer Avatar with Camera Badge (Tappable anywhere on avatar)
                      GestureDetector(
                        onTap: _showAvatarPickerModal,
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2.5),
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
                                  border: Border.all(color: Colors.white, width: 1.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'ვერიფიცირებული ფერმერი',
                                  child: SvgPicture.asset(
                                    AppAssets.verifiedBadge,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.sprout,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    (authState.farmName != null &&
                                            authState.farmName!.trim().isNotEmpty)
                                        ? authState.farmName!
                                        : 'ჩემი მეურნეობა',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 13.5,
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
}
