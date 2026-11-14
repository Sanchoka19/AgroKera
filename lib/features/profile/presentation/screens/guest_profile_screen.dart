import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/presentation/screens/categories_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'help_center_screen.dart';

/// Profile Screen with adaptive role support:
/// - Farmer Role: Specialized Business Profile with 3-stat metric card, verified banner, and grouped operations
/// - Customer/Guest Role: Grouped account sections, language/notifications, help center
class GuestProfileScreen extends ConsumerStatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  ConsumerState<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends ConsumerState<GuestProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'ქართული';

  void _openLanguageSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'აპლიკაციის ენა',
              style: AppTypography.h1.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...['ქართული', 'English'].map((lang) {
              final isSelected = lang == _selectedLanguage;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLanguage = lang);
                  Navigator.of(ctx).pop();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEBF7EF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // If logged in as Farmer, display the specialized Farmer Profile
    if (authState.role == UserRole.farmer) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildFarmerProfile(context, authState),
          ),
        ),
      );
    }

    // Default Customer / Guest Profile
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              if (!authState.isAuthenticated) ...[
                const GuestPromoBanner(showCloseButton: false),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(
                          LucideIcons.user,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.userName ?? 'მომხმარებელი',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${authState.role.displayName} • ${authState.userPhone ?? ''}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(authStateProvider.notifier).logout();
                        },
                        icon: const Icon(
                          LucideIcons.logOut,
                          color: AppColors.accentWarm,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section 1: ანგარიშის მართვა
              _buildSectionHeader('ანგარიშის მართვა'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileGroupItem(
                      icon: LucideIcons.shoppingBag,
                      title: 'ჩემი შეკვეთები',
                      isTop: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        requireAuth(
                          context,
                          ref: ref,
                          onAuthenticated: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('შეკვეთების ისტორია ცარიელია.'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                    _ProfileGroupItem(
                      icon: LucideIcons.mapPin,
                      title: 'ჩემი მისამართი',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        requireAuth(
                          context,
                          ref: ref,
                          onAuthenticated: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('მისამართების მართვა.')),
                            );
                          },
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                    _ProfileGroupItem(
                      icon: LucideIcons.creditCard,
                      title: 'საბანკო ანგარიშები',
                      isBottom: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        requireAuth(
                          context,
                          ref: ref,
                          onAuthenticated: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('საბანკო ბარათები & ანგარიშები.'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: პარამეტრები (Settings)
              _buildSectionHeader('პარამეტრები'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileGroupItem(
                      icon: LucideIcons.globe,
                      title: 'აპლიკაციის ენა',
                      isTop: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedLanguage,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                      onTap: _openLanguageSelector,
                    ),
                    const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                    _ProfileGroupItem(
                      icon: LucideIcons.bell,
                      title: 'შეტყობინებები',
                      isBottom: true,
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

              const SizedBox(height: 20),

              // Section 3: დახმარება და მხარდაჭერა
              _buildSectionHeader('დახმარება და მხარდაჭერა'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _ProfileGroupItem(
                  icon: LucideIcons.info,
                  title: 'დახმარების ცენტრი',
                  isTop: true,
                  isBottom: true,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // App Version Footer
              Center(
                child: Text(
                  'აგროკერა • ვერსია 1.0.0',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Specialized Farmer Profile Layout (matching user design)
  Widget _buildFarmerProfile(BuildContext context, AuthState authState) {
    final farmerName = authState.userName ?? 'რეზო ბერიძე';
    final farmerId = 'ID 3031223';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Farmer Header with Avatar, Name, ID and Notification Bell
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?w=400&auto=format&fit=crop&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryLight,
                      child: const Icon(LucideIcons.user, color: AppColors.primary, size: 28),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmerName,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ფერმერი • $farmerId',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Notification Bell with unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ახალი შეტყობინებები: 2 ახალი შეკვეთა მიღებულია!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(
                    LucideIcons.bell,
                    color: Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. 3-Column Metrics Card (ჯამური შემოსავალი 5000₾, შეკვეთები 100, შეფასება 4.5)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  icon: LucideIcons.wallet,
                  label: 'ჯამური\nშემოსავალი',
                  value: '5000₾',
                ),
              ),
              Container(width: 1, height: 50, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricCol(
                  icon: LucideIcons.shoppingCart,
                  label: 'შეკვეთების\nრაოდენობა',
                  value: '100',
                ),
              ),
              Container(width: 1, height: 50, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricCol(
                  icon: LucideIcons.shieldCheck,
                  label: 'საშუალო\nშეფასება',
                  value: '4.5',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Status Banner: თქვენი სტატუსი • ✔ ვერიფიცირებული
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F7EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.sprout,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'თქვენი სტატუსი',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle2,
                    size: 15,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ვერიფიცირებული',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ==========================================
        // 4. GROUP 1: საფერმო საქმიანობა
        // ==========================================
        _buildSectionHeader('საფერმო საქმიანობა'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _FarmerActionItem(
                icon: LucideIcons.shoppingBag,
                title: 'ჩემი პროდუქტები',
                isTop: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF1F5F9)),
              _FarmerActionItem(
                icon: LucideIcons.inbox,
                title: 'შემოსული შეკვეთები',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('შემოსული შეკვეთების სია აქტიურია კაბინეტში'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF1F5F9)),
              _FarmerActionItem(
                icon: LucideIcons.creditCard,
                title: 'ანგარიშსწორება',
                isBottom: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('საბანკო რეკვიზიტები: TBC • GE29TB...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ==========================================
        // 5. GROUP 2: ფერმის ლოკაცია
        // ==========================================
        _buildSectionHeader('ფერმის ლოკაცია'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _FarmerActionItem(
            icon: LucideIcons.mapPin,
            title: 'ჩემი მისამართი',
            isTop: true,
            isBottom: true,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('მისამართი: კახეთი, გურჯაანი'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // ==========================================
        // 6. GROUP 3: სისტემური და დახმარება
        // ==========================================
        _buildSectionHeader('სისტემური და დახმარება'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _FarmerActionItem(
                icon: LucideIcons.helpCircle,
                title: 'დახმარების ცენტრი',
                isTop: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF1F5F9)),
              _FarmerActionItem(
                icon: LucideIcons.settings,
                title: 'პარამეტრები',
                onTap: _openLanguageSelector,
              ),
              const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF1F5F9)),
              _FarmerActionItem(
                icon: LucideIcons.logOut,
                title: 'გამოსვლა',
                isBottom: true,
                iconColor: const Color(0xFFEF4444),
                textColor: const Color(0xFFEF4444),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(authStateProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // App Version
        Center(
          child: Text(
            'აგროკერა • ვერსია 1.0.0',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Metric column helper
  Widget _buildMetricCol({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F7EE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Farmer Specific Green Line-Art Action Item
class _FarmerActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isTop;
  final bool isBottom;
  final Color? iconColor;
  final Color? textColor;

  const _FarmerActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isTop = false,
    this.isBottom = false,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(18) : Radius.zero,
        bottom: isBottom ? const Radius.circular(18) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(18) : Radius.zero,
          bottom: isBottom ? const Radius.circular(18) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor ?? const Color(0xFF16A34A),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: iconColor ?? const Color(0xFF16A34A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileGroupItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isTop;
  final bool isBottom;
  final Widget? trailing;

  const _ProfileGroupItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isTop = false,
    this.isBottom = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.zero;
    if (isTop && isBottom) {
      borderRadius = BorderRadius.circular(18);
    } else if (isTop) {
      borderRadius = const BorderRadius.vertical(top: Radius.circular(18));
    } else if (isBottom) {
      borderRadius = const BorderRadius.vertical(bottom: Radius.circular(18));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF7EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              trailing ??
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: AppColors.primary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
