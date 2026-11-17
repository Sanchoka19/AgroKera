import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';

/// Modal bottom sheet allowing farmers to add delivery coverage for a city/region
/// with quick popular city suggestions, preset fees, or custom pricing.
class AddRegionBottomSheet extends StatefulWidget {
  final Set<String> existingRegions;
  final void Function(String city, double fee) onRegionAdded;

  const AddRegionBottomSheet({
    super.key,
    required this.existingRegions,
    required this.onRegionAdded,
  });

  static void show(
    BuildContext context, {
    required Set<String> existingRegions,
    required void Function(String city, double fee) onRegionAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => AddRegionBottomSheet(
        existingRegions: existingRegions,
        onRegionAdded: onRegionAdded,
      ),
    );
  }

  static const List<String> popularCities = [
    'თბილისი',
    'რუსთავი',
    'მცხეთა',
    'ბათუმი',
    'ქუთაისი',
    'გორი',
    'თელავი',
    'ყვარელი',
    'სიღნაღი',
  ];

  @override
  State<AddRegionBottomSheet> createState() => _AddRegionBottomSheetState();
}

class _AddRegionBottomSheetState extends State<AddRegionBottomSheet> {
  late final TextEditingController _cityController;
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _feeController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _cityController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _submit() {
    final city = _cityController.text.trim();
    final fee = double.tryParse(_feeController.text.trim()) ?? 10.0;

    if (city.isEmpty) {
      AppToast.error(context, 'მიუთითეთ რეგიონის / ქალაქის სახელი');
      return;
    }

    widget.onRegionAdded(city, fee);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ახალი რეგიონის დამატება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick City Suggestions
            Text(
              'სწრაფი არჩევა:',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AddRegionBottomSheet.popularCities
                  .where((c) => !widget.existingRegions.contains(c))
                  .map(
                    (city) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _cityController.text = city;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _cityController.text == city
                              ? AppColors.primaryLight
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _cityController.text == city
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          city,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: _cityController.text == city
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _cityController.text == city
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),

            // City input
            Text(
              'ქალაქი / რეგიონი',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cityController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'მაგ. თბილისი, გორი, ქუთაისი...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.primary,
                ),
                suffixIcon: _cityController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => setState(() => _cityController.clear()),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Fee Presets
            Text(
              'მიტანის საფასური (0 ₾ = უფასო მიტანა)',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [0.0, 5.0, 7.0, 10.0, 15.0].map((preset) {
                final isSelected =
                    double.tryParse(_feeController.text) == preset;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _feeController.text = preset.toInt().toString();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      preset == 0 ? 'უფასო (0 ₾)' : '${preset.toInt()} ₾',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Fee input
            TextField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'სხვა ფასი (₾)',
                suffixText: '₾',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'დამატება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

