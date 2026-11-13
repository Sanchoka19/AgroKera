import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

/// Screen 6: მომხმარებელი (Customer Role Registration / Overview Screen)
/// Matching Figma screenshot:
/// - Green rounded hero banner with white Customer SVG icon, "მომხმარებელი" title & description
/// - "თქვენი სარგებელი" tag pills
/// - "რეგისტრაცია მომხმარებლად" primary button
/// - "სხვა როლის არჩევა" secondary button
class CustomerRoleScreen extends ConsumerWidget {
  const CustomerRoleScreen({super.key});

  void _onRegister(BuildContext context, WidgetRef ref) {
    ref.read(authStateProvider.notifier).register(
      role: UserRole.customer,
      name: 'გიორგი ბერიძე',
      phone: '+995 599 12 34 56',
      email: 'customer@agrokera.ge',
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('წარმატებით დარეგისტრირდით მომხმარებლად!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Green Banner Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  AppAssets.customer,
                                  width: 36,
                                  height: 36,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'მომხმარებელი',
                                  style: AppTypography.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'იყიდე ეკოლოგიურად სუფთა\nპროდუქტები',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Section: თქვენი სარგებელი
                      Text(
                        'თქვენი სარგებელი',
                        style: AppTypography.h2.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        direction: Axis.vertical,
                        spacing: 12,
                        children: const [
                          _BenefitTag(label: 'ონლაინ ვაჭრობა'),
                          _BenefitTag(label: 'პროდუქტის ისტორიის ნახვა'),
                          _BenefitTag(label: 'ჯანსაღი პროდუქტების შეძენა'),
                        ],
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Primary: რეგისტრაცია მომხმარებლად
                      PrimaryButton(
                        text: 'რეგისტრაცია მომხმარებლად',
                        borderRadius: BorderRadius.circular(12),
                        height: 52,
                        onPressed: () => _onRegister(context, ref),
                      ),
                      const SizedBox(height: 12),

                      // Secondary: სხვა როლის არჩევა
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'სხვა როლის არჩევა',
                            style: AppTypography.button.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BenefitTag extends StatelessWidget {
  final String label;

  const _BenefitTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
