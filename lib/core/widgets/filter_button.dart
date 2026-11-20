import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Reusable modular Filter Button widget for AgroKera.
/// Can be placed alongside [AppSearchBar] or headers across any screen.
/// Automatically handles active filter visual state and count badge.
class FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final int badgeCount;
  final double size;

  const FilterButton({
    super.key,
    required this.onTap,
    this.isActive = false,
    this.badgeCount = 0,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = isActive || badgeCount > 0;

    return Semantics(
      button: true,
      label: 'ფილტრაცია',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: showBadge ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: showBadge ? AppColors.primary : const Color(0xFFE2E8F0),
                width: showBadge ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: showBadge ? AppColors.primary : AppColors.textPrimary,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.notoSansGeorgian(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  )
                else if (isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

