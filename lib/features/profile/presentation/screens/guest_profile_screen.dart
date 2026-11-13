import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'help_center_screen.dart';

/// Profile Screen with modern grouped sections:
/// - Header: Promo Banner (Guest) or User Info Card (Authenticated)
/// - Section 1: „ანგარიშის მართვა“ (My Orders, My Address, Bank Accounts)
/// - Section 2: „პარამეტრები“ (Language, Notifications)
/// - Section 3: „დახმარება და მხარდაჭერა“ (Help Center)
/// - Footer: App Version
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
          style: AppTypography.titleMedium.copyWith(
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
                        child: Icon(
                          authState.role == UserRole.farmer
                              ? LucideIcons.sprout
                              : LucideIcons.user,
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
