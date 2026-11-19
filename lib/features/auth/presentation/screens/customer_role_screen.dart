import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';

/// Screen: მომხმარებელი (Customer Role Modern Overview Screen)
/// Reimagined with Modern Hero Card & 2x2 Bento Feature Grid (No Emojis):
/// - Vibrant Organic Forest-to-Emerald Hero Card with Customer Character Vignette
/// - 2x2 Bento Feature Grid with clean vector icons and micro-copy
/// - Trust & Benefit Indicators ("თქვენი სარგებელი")
/// - Pinned/Sticky Bottom Action Bar with Primary & Secondary CTA Buttons
class CustomerRoleScreen extends ConsumerWidget {
  const CustomerRoleScreen({super.key});

  void _onRegister(BuildContext context, WidgetRef ref) {
    final currentAuth = ref.read(authStateProvider);
    final email = currentAuth.userEmail?.trim() ?? '';

    ref.read(authStateProvider.notifier).register(
      role: UserRole.customer,
      name: currentAuth.userName ?? 'მომხმარებელი',
      phone: currentAuth.userPhone,
      email: email.isNotEmpty ? email : 'customer@agrokera.ge',
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppToast.success(context, 'წარმატებით დარეგისტრირდით მომხმარებლად!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'როლის მიმოხილვა',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      // ==========================================
      // PINNED/STICKY BOTTOM ACTION BAR
      // ==========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primary CTA Button
              PrimaryButton(
                text: 'რეგისტრაცია მომხმარებლად',
                borderRadius: BorderRadius.circular(14),
                height: 50,
                onPressed: () => _onRegister(context, ref),
              ),
              const SizedBox(height: 8),

              // Secondary: სხვა როლის არჩევა
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.arrowLeft,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'სხვა როლის არჩევა',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. HERO CARD: Gradient, Character & Badge
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const RadialGradient(
                    center: Alignment(0.85, -0.2),
                    radius: 1.25,
                    colors: [
                      Color(0xFF22C55E), // Radiant Emerald spotlight behind character
                      Color(0xFF16A34A), // Brand Vibrant Emerald
                      Color(0xFF15803D), // Deep Forest Green
                      Color(0xFF14532D), // Rich Dark Emerald for high-contrast text backing
                    ],
                    stops: [0.0, 0.35, 0.70, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14532D).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Texts and Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 100% Organic Badge (Vector icon, no emojis)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.leaf,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '100% ნატურალური',
                                  style: GoogleFonts.notoSansGeorgian(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Title with FittedBox (Guarantees single line on every screen, never wraps)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'მომხმარებელი',
                              style: GoogleFonts.notoSansGeorgian(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            'იყიდე ეკოლოგიურად სუფთა პროდუქტები პირდაპირ ფერმიდან',
                            style: GoogleFonts.notoSansGeorgian(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Right: Character Illustration in Circular Frame
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            AppAssets.customerRole,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 2. SECTION HEADER
              // ==========================================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.gem,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'თქვენი სარგებელი',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ==========================================
              // 3. 2x2 BENTO FEATURE GRID (Pure Vectors, No Emojis)
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.shoppingBag,
                      iconColor: AppColors.primary,
                      iconBg: const Color(0xFFEBF7EF),
                      title: 'ონლაინ ვაჭრობა',
                      description: 'ნატურალური პროდუქტების სწრაფი და მარტივი შეძენა პირდაპირ ფერმიდან.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.sprout,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'ჯანსაღი პროდუქტები',
                      description: '100% ეკოლოგიურად სუფთა, ქართული და უსაფრთხო მოსავალი.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.mapPin,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'პროდუქტის ისტორია',
                      description: 'გაიგე ზუსტად ვინ, სად და რა პირობებში მოიყვანა შენი პროდუქტი.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.truck,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFFF0FDFA),
                      title: 'სწრაფი მიტანა',
                      description: 'მოქნილი და გარანტირებული მიწოდება პირდაპირ თქვენს კართან.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==========================================
              // 4. BENEFIT BADGES
              // ==========================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'გარანტირებული სტანდარტი',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _BenefitPill(
                          icon: LucideIcons.award,
                          label: '100% ქართული ხარისხი',
                        ),
                        _BenefitPill(
                          icon: LucideIcons.heartHandshake,
                          label: 'ფერმერების მხარდაჭერა',
                        ),
                        _BenefitPill(
                          icon: LucideIcons.gem,
                          label: 'პრემიუმ ასორტიმენტი',
                        ),
                        _BenefitPill(
                          icon: LucideIcons.shieldCheck,
                          label: 'უსაფრთხო ანგარიშსწორება',
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
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              height: 1.35,
              color: const Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
