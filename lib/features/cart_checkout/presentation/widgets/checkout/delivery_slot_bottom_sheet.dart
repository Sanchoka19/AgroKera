import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_filter_tab.dart';
import '../../../../marketplace/data/models/farmer_model.dart';
import '../../../domain/models/delivery_schedule_model.dart';
import '../../../domain/services/checkout_service.dart';

/// Modal bottom sheet for selecting an available delivery date and time slot.
///
/// Features a compact 2-tiered selector using the universal [AppFilterTab]:
/// 1. Horizontal date selector tabs
/// 2. Time window selector tabs
/// 3. Confirmation CTA with chosen slot preview
class DeliverySlotBottomSheet extends StatefulWidget {
  final FarmerModel farmer;
  final List<DeliveryDateSchedule> schedules;
  final String activeSlot;
  final ValueChanged<String> onSlotSelected;

  const DeliverySlotBottomSheet({
    super.key,
    required this.farmer,
    required this.schedules,
    required this.activeSlot,
    required this.onSlotSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required FarmerModel farmer,
    List<DeliveryDateSchedule>? schedules,
    List<String>? slots,
    required String activeSlot,
    required ValueChanged<String> onSlotSelected,
  }) {
    final effectiveSchedules = schedules ??
        CheckoutService.generateDeliverySchedules(farmer);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DeliverySlotBottomSheet(
        farmer: farmer,
        schedules: effectiveSchedules,
        activeSlot: activeSlot,
        onSlotSelected: onSlotSelected,
      ),
    );
  }

  @override
  State<DeliverySlotBottomSheet> createState() => _DeliverySlotBottomSheetState();
}

class _DeliverySlotBottomSheetState extends State<DeliverySlotBottomSheet> {
  late int _selectedDateIndex;
  late String _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _initInitialSelection();
  }

  void _initInitialSelection() {
    _selectedDateIndex = 0;

    if (widget.schedules.isEmpty) {
      _selectedTimeSlot = '10:00 - 13:00';
      return;
    }

    // Try matching activeSlot with existing schedules and time slots
    final active = widget.activeSlot.trim();
    bool matched = false;

    for (int i = 0; i < widget.schedules.length; i++) {
      final s = widget.schedules[i];
      if (active.contains(s.weekdayName) && active.contains(s.dayMonthFormatted)) {
        _selectedDateIndex = i;
        for (final t in s.timeSlots) {
          if (active.contains(t)) {
            _selectedTimeSlot = t;
            matched = true;
            break;
          }
        }
        if (matched) break;
      }
    }

    if (!matched) {
      final current = widget.schedules[_selectedDateIndex];
      _selectedTimeSlot =
          current.timeSlots.isNotEmpty ? current.timeSlots.first : '10:00 - 13:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'მიწოდების დრო მიუწვდომელია',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final currentSchedule = widget.schedules[_selectedDateIndex];
    final farmerDeliveryDays = widget.farmer.deliveryDays.isNotEmpty
        ? widget.farmer.deliveryDays.join(', ')
        : 'შაბათი';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.calendarClock,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'მიტანის დროის არჩევა',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'ფერმერის მიწოდების დღეები: $farmerDeliveryDays',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tier 1: Delivery Date Selector (Horizontal scroll with AppFilterTab)
            Text(
              'მიტანის თარიღი',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(widget.schedules.length, (index) {
                  final schedule = widget.schedules[index];
                  final isSelected = _selectedDateIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterTab(
                      label: schedule.tabLabel,
                      isSelected: isSelected,
                      icon: Icon(
                        LucideIcons.calendar,
                        size: 13.5,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedDateIndex = index;
                          if (!schedule.timeSlots.contains(_selectedTimeSlot)) {
                            _selectedTimeSlot = schedule.timeSlots.first;
                          }
                        });
                      },
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 18),

            // Tier 2: Time Window Selector (Tabs with AppFilterTab)
            Text(
              'საათობრივი შუალედი',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentSchedule.timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return AppFilterTab(
                  label: slot,
                  isSelected: isSelected,
                  icon: Icon(
                    LucideIcons.clock,
                    size: 13.5,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  onTap: () {
                    setState(() => _selectedTimeSlot = slot);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // Confirmation CTA button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final chosen = currentSchedule.fullSlotString(_selectedTimeSlot);
                  widget.onSlotSelected(chosen);
                  Navigator.pop(context);
                },
                child: Text(
                  'დადასტურება • ${currentSchedule.weekdayName}, $_selectedTimeSlot',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
