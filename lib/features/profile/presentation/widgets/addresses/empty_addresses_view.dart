import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/constants/app_assets.dart';
import 'package:agrokera/core/theme/app_colors.dart';

/// Clean empty state placeholder when the user has no saved addresses.
class EmptyAddressesView extends StatelessWidget {
  final VoidCallback onAddAddress;

  const EmptyAddressesView({
    super.key,
    required this.onAddAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.emptyAddresses,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'შენახული მისამართები არ გაქვთ',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'დაამატეთ თქვენი სახლის, სამსახურის ან მეურნეობის ლოკაცია სწრაფი შეკვეთისა და მიწოდებისთვის.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
                height: 1.45,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddAddress,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(
                'ახალი მისამართის დამატება',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
