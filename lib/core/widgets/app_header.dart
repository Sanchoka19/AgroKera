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
  final bool showBack;
  final bool centerTitle;
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
    this.showBack = false,
    this.centerTitle = false,
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
                Expanded(child: titleWidget!)
              else if (title != null)
                Expanded(
                  child: centerTitle
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            if (showBack)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).maybePop(),
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      LucideIcons.arrowLeft,
                                      size: 20,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: showBack ? 36.0 : 0.0,
                              ),
                              child: Text(
                                title!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (showBack) ...[
                              InkWell(
                                onTap: () => Navigator.of(context).maybePop(),
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    LucideIcons.arrowLeft,
                                    size: 20,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                title!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
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
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            LucideIcons.bell,
                            size: 24,
                            color: AppColors.primary,
                          ),
                          if (authState.isAuthenticated && unreadNotifs > 0)
                            _buildCountBadge(
                              unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                            ),
                        ],
                      ),
                    ),

                  // Cart Icon
                  if (showCart)
                    IconButton(
                      tooltip: 'კალათა',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(),
                          ),
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
                          if (cartItems.isNotEmpty)
                            _buildCountBadge(
                              cartItems.length > 9 ? '9+' : '${cartItems.length}',
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

  Widget _buildCountBadge(String text) {
    return Positioned(
      top: -5,
      right: -4,
      child: Container(
        padding: const EdgeInsets.all(2),
        constraints: const BoxConstraints(
          minWidth: 17,
          minHeight: 17,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
