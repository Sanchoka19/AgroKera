import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';

/// Modal bottom sheet explaining delivery fee calculation and weight tiers.
class DeliveryFeeExplanationSheet extends StatelessWidget {
  final double totalWeight;
  final double baseFee;
  final double heavyFee;
  final double totalFee;
  final DeliveryVehicleType vehicleType;
  final bool isPickup;

  const DeliveryFeeExplanationSheet({
    super.key,
    required this.totalWeight,
    required this.baseFee,
    required this.heavyFee,
    required this.totalFee,
    required this.vehicleType,
    required this.isPickup,
  });

  static Future<void> show({
    required BuildContext context,
    required double totalWeight,
    required double baseFee,
    required double heavyFee,
    required double totalFee,
    required DeliveryVehicleType vehicleType,
    required bool isPickup,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DeliveryFeeExplanationSheet(
        totalWeight: totalWeight,
        baseFee: baseFee,
        heavyFee: heavyFee,
        totalFee: totalFee,
        vehicleType: vehicleType,
        isPickup: isPickup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F7EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.truck,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'მიტანის საფასურის გაანგარიშება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'ტარიფი დამოკიდებულია მიტანის ზონასა და ტრანსპორტირებაზე',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'მიტანის ჯამური საფასური:',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                Text(
                  isPickup
                      ? '0 ₾ (თვითგატანა)'
                      : '${totalFee.toStringAsFixed(0)} ₾',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isPickup
                        ? const Color(0xFF2E7D32)
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ტარიფები წონის მიხედვით:',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _DeliveryTierItem(
            title: 'სტანდარტული მიტანა (0 - 20 კგ)',
            subtitle: 'სტანდარტული კურიერი • საბაზისო საფასური',
            feeText: '${baseFee.toStringAsFixed(0)} ₾',
            isActive:
                !isPickup && vehicleType == DeliveryVehicleType.standardCourier,
            icon: LucideIcons.bike,
          ),
          const SizedBox(height: 8),
          _DeliveryTierItem(
            title: 'მსუბუქი ავტომობილი (20.01 - 60 კგ)',
            subtitle:
                'საბაზისო (${baseFee.toStringAsFixed(0)} ₾) + მძიმე ტვირთი (8 ₾)',
            feeText: '${(baseFee + 8.0).toStringAsFixed(0)} ₾',
            isActive:
                !isPickup && vehicleType == DeliveryVehicleType.passengerCar,
            icon: LucideIcons.car,
          ),
          const SizedBox(height: 8),
          _DeliveryTierItem(
            title: 'სატვირთო / მინივენი (60.01 - 250 კგ)',
            subtitle:
                'საბაზისო (${baseFee.toStringAsFixed(0)} ₾) + სატვირთო (45 ₾)',
            feeText: '${(baseFee + 45.0).toStringAsFixed(0)} ₾',
            isActive:
                !isPickup && vehicleType == DeliveryVehicleType.cargoVan,
            icon: LucideIcons.truck,
          ),
          const SizedBox(height: 8),
          _DeliveryTierItem(
            title: 'თვითგატანა (250+ კგ ან არჩეული)',
            subtitle:
                '250 კგ-ზე მეტ წონაზე საკურიერო მიტანა არ ხორციელდება',
            feeText: '0 ₾',
            isActive: isPickup,
            icon: LucideIcons.store,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'გასაგებია',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTierItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String feeText;
  final bool isActive;
  final IconData icon;

  const _DeliveryTierItem({
    required this.title,
    required this.subtitle,
    required this.feeText,
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F7EE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primary : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12.5,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'მიმდინარე',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            feeText,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isActive ? AppColors.primary : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
