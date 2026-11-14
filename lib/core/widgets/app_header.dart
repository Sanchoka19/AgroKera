import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/cart_checkout/presentation/providers/cart_provider.dart';
import '../../features/cart_checkout/presentation/screens/cart_screen.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../auth/auth_state_provider.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';
import 'auth_required_bottom_sheet.dart';

/// Unified Top Header across all primary screens in AgroKera.
/// Ensures 100% visual harmony, uniform spacing, and cohesive brand experience.
class AppHeader extends ConsumerWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showLogo;
  final bool showNotificationBell;
  final bool showCart;
  final Widget? searchBar;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.showLogo = false,
    this.showNotificationBell = true,
    this.showCart = false,
    this.searchBar,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final cartItems = ref.watch(cartProvider);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Brand Logo / Title & Global Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Logo or Screen Title
              if (showLogo)
                const AppLogo()
              else if (titleWidget != null)
                titleWidget!
              else if (title != null)
                Text(
                  title!,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                )
              else
                const SizedBox.shrink(),

              // Right: Action Icons (Bell, Cart, custom)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...?actions,

                  // Notification Bell Icon
                  if (showNotificationBell)
                    IconButton(
                      tooltip: 'შეტყობინებები',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            LucideIcons.bell,
                            size: 24,
                            color: AppColors.primary,
                          ),
                          if (unreadNotifs > 0)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Cart Icon
                  if (showCart)
                    IconButton(
                      tooltip: 'კალათა',
                      onPressed: () {
                        requireAuth(
                          context,
                          ref: ref,
                          onAuthenticated: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            );
                          },
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            LucideIcons.shoppingCart,
                            size: 24,
                            color: AppColors.primary,
                          ),
                          if (authState.isAuthenticated && cartItems.isNotEmpty)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentWarm,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${cartItems.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Row 2: Search Bar (if provided)
          if (searchBar != null) ...[
            const SizedBox(height: 10),
            searchBar!,
          ],
        ],
      ),
    );
  }
}
