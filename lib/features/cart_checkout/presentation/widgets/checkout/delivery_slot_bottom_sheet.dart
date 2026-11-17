import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../marketplace/data/models/farmer_model.dart';

/// Modal bottom sheet for selecting an available delivery time slot.
class DeliverySlotBottomSheet extends StatelessWidget {
  final FarmerModel farmer;
  final List<String> slots;
  final String activeSlot;
  final ValueChanged<String> onSlotSelected;

  const DeliverySlotBottomSheet({
    super.key,
    required this.farmer,
    required this.slots,
    required this.activeSlot,
    required this.onSlotSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required FarmerModel farmer,
    required List<String> slots,
    required String activeSlot,
    required ValueChanged<String> onSlotSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeliverySlotBottomSheet(
        farmer: farmer,
        slots: slots,
        activeSlot: activeSlot,
        onSlotSelected: onSlotSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'აირჩიეთ მიტანის დრო',
            style: AppTypography.h1.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'ფერმერის მიწოდების დღეები: ${farmer.deliveryDays.isNotEmpty ? farmer.deliveryDays.join(", ") : "შაბათი"}',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...slots.map(
            (s) => ListTile(
              title: Text(
                s,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: activeSlot == s
                  ? const Icon(LucideIcons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                onSlotSelected(s);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

