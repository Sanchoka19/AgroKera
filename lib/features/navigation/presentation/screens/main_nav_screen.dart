import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/farm_inventory/presentation/screens/farmer_dashboard_screen.dart';
import '../../../marketplace/presentation/screens/categories_screen.dart';
import '../../../marketplace/presentation/screens/home_screen.dart';
import '../../../profile/presentation/screens/guest_profile_screen.dart';

/// Navigation Tab Item Definition
class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({
    required this.icon,
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
  }

  @override
  Widget build(BuildContext context) {
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
          icon: LucideIcons.briefcase,
          label: 'კაბინეტი',
        ),
      const _NavItemData(
        icon: LucideIcons.user,
        label: 'პროფილი',
      ),
    ];

    // Ensure _currentIndex is clamped if screen count changes dynamically
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
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
                      borderRadius: BorderRadius.circular(24),
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
                              ? const Color(0xFF042F2E) // Deep Midnight-Teal Pill
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
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
