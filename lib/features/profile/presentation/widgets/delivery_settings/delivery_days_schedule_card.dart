import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';

/// Card allowing farmers to select and configure delivery weekdays.
class DeliveryDaysScheduleCard extends StatelessWidget {
  final List<String> selectedDays;
  final ValueChanged<List<String>> onDaysChanged;

  const DeliveryDaysScheduleCard({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  static const Map<String, String> shortToFullDay = {
    'ორშ': 'ორშაბათი',
    'სამ': 'სამშაბათი',
    'ოთხ': 'ოთხშაბათი',
    'ხუთ': 'ხუთშაბათი',
    'პარ': 'პარასკევი',
    'შაბ': 'შაბათი',
    'კვი': 'კვირა',
    'ორშაბათი': 'ორშაბათი',
    'სამშაბათი': 'სამშაბათი',
    'ოთხშაბათი': 'ოთხშაბათი',
    'ხუთშაბათი': 'ხუთშაბათი',
    'პარასკევი': 'პარასკევი',
    'შაბათი': 'შაბათი',
    'კვირა': 'კვირა',
  };

  static String normalizeDay(String d) => shortToFullDay[d.trim()] ?? d.trim();

  static const List<String> allWeekdays = [
    'ორშაბათი',
    'სამშაბათი',
    'ოთხშაბათი',
    'ხუთშაბათი',
    'პარასკევი',
    'შაბათი',
    'კვირა',
  ];

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
              const Icon(
                LucideIcons.calendar,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'მიტანის დღეები',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'მონიშნეთ კვირის დღეები, როცა ახორციელებთ შეკვეთების მიწოდებას:',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allWeekdays.map((day) {
              final normalizedDay = normalizeDay(day);
              final isSelected = selectedDays.any(
                (d) => normalizeDay(d) == normalizedDay,
              );
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF1F5F9),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                ),
                onSelected: (selected) {
                  final updated = List<String>.from(selectedDays);
                  if (selected) {
                    if (!updated.any((d) => normalizeDay(d) == normalizedDay)) {
                      updated.add(normalizedDay);
                    }
                  } else {
                    updated.removeWhere((d) => normalizeDay(d) == normalizedDay);
                  }
                  onDaysChanged(updated);
                },
              );
            }).toList(),
          ),
          if (selectedDays.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'აქტიური გრაფიკი: ${allWeekdays.where((d) => selectedDays.any((sd) => normalizeDay(sd) == d)).join(", ")}',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

