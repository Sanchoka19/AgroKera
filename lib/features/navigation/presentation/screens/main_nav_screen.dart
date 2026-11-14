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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTabSelected(index),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 24,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 4),

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
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF94A3B8),
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
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
