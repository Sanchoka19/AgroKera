import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../farmer_onboarding/presentation/widgets/farmer_map_widget.dart';

/// Modal bottom sheet for choosing or updating the delivery address with GPS & quick chips.
class DeliveryAddressBottomSheet extends StatefulWidget {
  final String initialAddress;
  final ValueChanged<String> onAddressSelected;

  const DeliveryAddressBottomSheet({
    super.key,
    required this.initialAddress,
    required this.onAddressSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentAddress,
    required ValueChanged<String> onAddressSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DeliveryAddressBottomSheet(
        initialAddress: currentAddress,
        onAddressSelected: onAddressSelected,
      ),
    );
  }

  @override
  State<DeliveryAddressBottomSheet> createState() =>
      _DeliveryAddressBottomSheetState();
}

class _DeliveryAddressBottomSheetState
    extends State<DeliveryAddressBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildQuickChip(String label, String fullAddress) {
    final isSelected = _controller.text.trim() == fullAddress;
    return InkWell(
      onTap: () {
        setState(() {
          _controller.text = fullAddress;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                )
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchGpsLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (!mounted) return;
          AppToast.error(context, 'მდებარეობაზე წვდომის ნებართვა უარყოფილია');
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      final resolved = await GeorgianGeoLookup.resolveDetailedAddress(
        LatLng(pos.latitude, pos.longitude),
      );
      if (!mounted) return;
      setState(() => _controller.text = resolved);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'GPS მდებარეობის დადგენა ვერ მოხერხდა');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    Text(
                      'მიტანის მისამართი',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
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

            // TextField with clear button & search icon
            TextField(
              controller: _controller,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'შეიყვანეთ მისამართი (ქალაქი, ქუჩა)...',
                hintStyle: GoogleFonts.notoSansGeorgian(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.primary,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          setState(() => _controller.clear());
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Quick City Selector Pills
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
              children: [
                _buildQuickChip('თბილისი', 'ჭავჭავაძე - თბილისი'),
                _buildQuickChip('რუსთავი', 'რუსთავი, შარტავას 4'),
                _buildQuickChip('მცხეთა', 'მცხეთა, არსუკიძის 1'),
                _buildQuickChip('ბათუმი', 'ბათუმი, რუსთაველის 10'),
              ],
            ),
            const SizedBox(height: 14),

            // GPS Locator Button
            OutlinedButton.icon(
              onPressed: _fetchGpsLocation,
              icon: const Icon(
                LucideIcons.locateFixed,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                'ჩემი მდებარეობის დადგენა (GPS)',
                style: GoogleFonts.notoSansGeorgian(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
            const SizedBox(height: 16),

            // Save CTA Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final trimmed = _controller.text.trim();
                  if (trimmed.isNotEmpty) {
                    widget.onAddressSelected(trimmed);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'მისამართის შენახვა',
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

