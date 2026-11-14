import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../farm_inventory/presentation/screens/farmer_dashboard_screen.dart';
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
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = index == safeIndex;

                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onTabSelected(index),
                      splashColor: AppColors.primary.withValues(alpha: 0.08),
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Active pill container around the icon
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              height: 32,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected
                                    ? (navItems.length > 3 ? 14 : 18)
                                    : 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                item.icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Label text wrapped in FittedBox to guarantee single-line fit
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: isSelected ? 11.5 : 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFF64748B),
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
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
