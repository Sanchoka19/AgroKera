import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../farmer_onboarding/presentation/screens/farmer_onboarding_screen.dart';

/// Screen: ფერმერი (Farmer Role Modern Overview Screen)
/// Reimagined with Modern Hero Card & 2x2 Bento Feature Grid (No Emojis):
/// - Vibrant Organic Forest-to-Emerald Hero Card with Farmer Character Vignette
/// - 2x2 Bento Feature Grid with clean vector icons and micro-copy
/// - Trust & Benefit Indicators ("თქვენი სარგებელი")
/// - Bold Primary & Secondary CTA Buttons
class FarmerRoleScreen extends ConsumerWidget {
  const FarmerRoleScreen({super.key});

  void _onRegister(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FarmerOnboardingScreen(),
      ),
    );
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
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
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
                text: 'რეგისტრაცია ფერმერად',
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B4332), // Deep Forest Green
                      Color(0xFF2D6A4F), // Emerald Green
                      Color(0xFF53B175), // Vibrant Brand Green
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
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
                          // AgroKera Partner Badge (Vector icon, no emojis)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.sparkles,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'AgroKera Partner',
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
                              'ფერმერი',
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
                            'მოაწყვე და მართე შენი ფერმა ციფრულად',
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
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SvgPicture.asset(
                            AppAssets.farmerRole,
                            fit: BoxFit.contain,
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
                    child: const Icon(
                      LucideIcons.layoutGrid,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'რისი გაკეთება შეგიძლია:',
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
                      icon: LucideIcons.circleDollarSign,
                      iconColor: AppColors.primary,
                      iconBg: const Color(0xFFEBF7EF),
                      title: 'პროდუქტების გაყიდვა',
                      description: 'პირდაპირი წვდომა რესტორნებსა და კლიენტებზე შუამავლების გარეშე.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.packageCheck,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'მოსავლის მართვა',
                      description: 'მარაგების აღრიცხვა, ფასების კონტროლი და ციფრული კატალოგი.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.barChart3,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'ბაზრის ანალიტიკა',
                      description: 'მოთხოვნისა და რეალური საბაზრო ფასების დინამიკური ანალიზი.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoCard(
                      icon: LucideIcons.truck,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFFF0FDFA),
                      title: 'მოქნილი ლოგისტიკა',
                      description: 'ტრანსპორტირებისა და შეკვეთების მიწოდების სწრაფი ორგანიზება.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==========================================
              // 4. BENEFIT BADGES ("თქვენი სარგებელი")
              // ==========================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'თქვენი სარგებელი',
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
                          icon: LucideIcons.badgePercent,
                          label: '0% საკომისიო საწყის ეტაპზე',
                        ),
                        _BenefitPill(
                          icon: LucideIcons.badgeCheck,
                          label: 'ვერიფიცირებული პარტნიორი',
                        ),
                        _BenefitPill(
                          icon: LucideIcons.wallet,
                          label: 'მაღალი შემოსავალი',
                        ),
                        _BenefitPill(
                          icon: LucideIcons.arrowUpRight,
                          label: 'პირდაპირი გაყიდვები',
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
