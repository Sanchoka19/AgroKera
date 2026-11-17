import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';

/// Card displaying self-pickup store status and address input with GPS lookup.
class FarmPickupAddressCard extends StatelessWidget {
  final TextEditingController locationController;
  final bool isLocatingGps;
  final VoidCallback onGpsLocate;

  const FarmPickupAddressCard({
    super.key,
    required this.locationController,
    required this.isLocatingGps,
    required this.onGpsLocate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.store,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'თვითგატანა მეურნეობიდან',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'საბაზისო პირობა • უფასო',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'მეურნეობის მისამართი (თვითგატანის წერტილი):',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: locationController,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                LucideIcons.mapPin,
                size: 18,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                tooltip: 'ჩემი მდებარეობის დადგენა (GPS)',
                icon: isLocatingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        LucideIcons.locateFixed,
                        size: 20,
                        color: AppColors.primary,
                      ),
                onPressed: isLocatingGps ? null : onGpsLocate,
              ),
              hintText: 'მაგ. კახეთი, გურჯაანი, სოფელი ჩუმლაყი',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

