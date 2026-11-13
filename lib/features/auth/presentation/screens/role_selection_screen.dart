import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'customer_role_screen.dart';
import 'farmer_role_screen.dart';

/// Screen 4: აირჩიე როლი (Role Selection Screen)
/// Matching Figma screenshot:
/// - AppBar with back button & "აირჩიე როლი" title
/// - Farmer Section:
///   - Official Farmer SVG icon (#4B5563)
///   - "მე ვარ ფერმერი" green button (#53B175)
///   - "მოაწყვე და მართე შენი ფერმა" description
/// - Divider
/// - Customer Section:
///   - Official Customer SVG icon (#4B5563)
///   - "მე ვარ მომხმარებელი" green button (#53B175)
///   - "იყიდე ეკოლოგიურად სუფთა პროდუქტები" description
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'აირჩიე როლი',
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Farmer Section
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: SvgPicture.asset(
                          AppAssets.farmer,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 240,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FarmerRoleScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'მე ვარ ფერმერი',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'მოაწყვე და მართე შენი ფერმა',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Divider between sections
            const Divider(
              color: Color(0xFFF1F5F9),
              thickness: 2,
              height: 2,
            ),

            // Customer Section
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: SvgPicture.asset(
                          AppAssets.customer,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 240,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CustomerRoleScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'მე ვარ მომხმარებელი',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'იყიდე ეკოლოგიურად სუფთა პროდუქტები',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
