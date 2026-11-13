import 'package:flutter/material.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/features/marketplace/presentation/screens/categories_screen.dart';
import 'package:agrokera/features/marketplace/presentation/screens/home_screen.dart';
import 'package:agrokera/features/profile/presentation/screens/guest_profile_screen.dart';

/// Main Bottom Navigation Shell adhering to Figma screenshots:
/// 3 tabs with filled active icons and bolder active typography:
/// 1. მთავარი (Home)
/// 2. მარკეტი (Categories & Agro Market)
/// 3. პროფილი (Profile / Guest Profile)
class MainNavScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      const GuestProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
          unselectedLabelStyle: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.home_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              label: 'მთავარი',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.storefront_outlined, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              label: 'მარკეტი',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.person_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              label: 'პროფილი',
            ),
          ],
        ),
      ),
    );
  }
}
