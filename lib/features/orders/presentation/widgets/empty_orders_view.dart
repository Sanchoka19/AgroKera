import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../domain/models/farmer_order_model.dart';

/// Clean Empty State for Incoming Orders screen
class EmptyOrdersView extends StatelessWidget {
  final OrderStatus? filter;
  final VoidCallback? onResetFilter;

  const EmptyOrdersView({
    super.key,
    this.filter,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    final title = filter == null
        ? 'თქვენ არ გაქვთ შეკვეთები'
        : 'შეკვეთები არ მოიძებნა';

    final subtitle = filter == null
        ? 'როდესაც მყიდველები განათავსებენ ახალ შეკვეთებს, ისინი გამოჩნდება აქ'
        : 'კატეგორიაში „${filter!.label}“ ამჟამად აქტიური შეკვეთები არ არის';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated SVG empty state
            SvgPicture.asset(
              AppAssets.emptyOrders,
              height: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),

            if (filter != null && onResetFilter != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onResetFilter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: Text(
                  'ყველა შეკვეთის ნახვა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
