import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';

/// Card allowing farmers to enable or disable courier delivery services.
class DeliveryCourierToggleCard extends StatelessWidget {
  final bool isDeliveryEnabled;
  final ValueChanged<bool> onToggle;

  const DeliveryCourierToggleCard({
    super.key,
    required this.isDeliveryEnabled,
    required this.onToggle,
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
                  color: isDeliveryEnabled
                      ? AppColors.primaryLight
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.truck,
                  color: isDeliveryEnabled
                      ? AppColors.primary
                      : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'საკურიერო მიტანა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDeliveryEnabled
                          ? 'მიტანის სერვისი აქტიურია'
                          : 'მიტანა გამორთულია',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        color: isDeliveryEnabled
                            ? AppColors.primaryDark
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDeliveryEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ჩართეთ, თუ მყიდველებს თქვენს მიერ მითითებულ რეგიონებში თავად უზრუნველყოფთ პროდუქციის მიტანას.',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

