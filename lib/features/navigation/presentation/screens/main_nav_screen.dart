import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/constants/app_assets.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/offline_status_banner.dart';
import 'package:agrokera/features/farm_inventory/presentation/screens/farmer_dashboard_screen.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/screens/categories_screen.dart';
import '../../../marketplace/presentation/screens/home_screen.dart';
import '../../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../../profile/presentation/screens/guest_profile_screen.dart';

/// Navigation Tab Item Definition
class _NavItemData {
  final IconData? icon;
  final String? svgAsset;
  final String label;

  const _NavItemData({
    this.icon,
    this.svgAsset,
    required this.label,
  });
}

/// Modern Bottom Navigation Bar Shell
/// Engineered to dynamically adapt between 3-tab (Guest/Customer) and 4-tab (Farmer) layouts:
/// - Pure Lucide vector icons
/// - Smooth animated pill highlight for active tab
/// - Adaptive FittedBox typography ensuring zero text wrapping or crowding on any screen
/// - Tactile haptic feedback on tab changes
/// - Safe gesture padding and crisp modern elevation
class MainNavScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    unawaited(ref.read(marketplaceProvider.notifier).refreshFromBackend());
    unawaited(ref.read(farmerOrdersProvider.notifier).refreshFromBackend());
  }

  @override
  Widget build(BuildContext context) {
    // Automatically switch to Home ('მთავარი', index 0) upon login, logout, or role change
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      final loggedInNow = !(previous?.isAuthenticated ?? false) && next.isAuthenticated;
      final loggedOutNow = (previous?.isAuthenticated ?? false) && !next.isAuthenticated;
      final roleChanged = previous?.role != next.role && next.isAuthenticated;
      if ((loggedInNow || loggedOutNow || roleChanged) && _currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
    });

    final authState = ref.watch(authStateProvider);
    final isFarmer = authState.role == UserRole.farmer;

    // Screens and Tab definitions dynamically driven by role
    final List<Widget> screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      if (isFarmer) const FarmerDashboardScreen(),
      const GuestProfileScreen(),
    ];

    final List<_NavItemData> navItems = [
      const _NavItemData(
        icon: LucideIcons.house,
        label: 'მთავარი',
      ),
      const _NavItemData(
        icon: LucideIcons.store,
        label: 'მარკეტი',
      ),
      if (isFarmer)
        const _NavItemData(
          svgAsset: AppAssets.barnIcon,
          label: 'ფერმა',
        ),
      const _NavItemData(
        icon: LucideIcons.user,
        label: 'პროფილი',
      ),
    ];

    // Ensure _currentIndex is clamped if screen count changes dynamically
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineStatusBanner(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = index == safeIndex;

                return Semantics(
                  label: item.label,
                  selected: isSelected,
                  child: Tooltip(
                    message: item.label,
                    child: InkWell(
                      key: ValueKey('nav_tab_${item.label}'),
                      onTap: () => _onTabSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOutCubic,
                        padding: isSelected
                            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary // Lightened Emerald/Teal Pill (#0F766E)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.svgAsset != null)
                              SvgPicture.asset(
                                item.svgAsset!,
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  isSelected ? Colors.white : const Color(0xFF64748B),
                                  BlendMode.srcIn,
                                ),
                              )
                            else
                              Icon(
                                item.icon!,
                                size: 21,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeInOutCubic,
                                child: isSelected
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            item.label,
                                            style: GoogleFonts.notoSansGeorgian(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
