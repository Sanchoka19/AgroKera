import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/guest_promo_banner.dart';
import 'help_center_screen.dart';

/// Guest Profile Screen adhering to Screenshot 7:
/// - Top promo card "არ გაქვს ანგარიში? ... ავტორიზაცია | რეგისტრაცია"
/// - List items with green icons & chevrons:
///   1. ჩემი შეკვეთები (My Orders) - requires auth
///   2. ჩემი მისამართი (My Address) - requires auth
///   3. საბანკო ანგარიშები (Bank Accounts) - requires auth
///   4. დახმარების ცენტრი (Help Center) - public
class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
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
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(
                          LucideIcons.user,
                          size: 32,
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
                              authState.userPhone ?? '',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
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

              // Menu List Items
              _ProfileMenuItem(
                icon: LucideIcons.shoppingBag,
                title: 'ჩემი შეკვეთები',
                onTap: () {
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
              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: LucideIcons.mapPin,
                title: 'ჩემი მისამართი',
                onTap: () {
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
              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: LucideIcons.creditCard,
                title: 'საბანკო ანგარიშები',
                onTap: () {
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
              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: LucideIcons.info,
                title: 'დახმარების ცენტრი',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
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
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
