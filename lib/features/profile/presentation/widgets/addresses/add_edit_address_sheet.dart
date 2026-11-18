import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';

/// Modal bottom sheet for adding or editing a delivery / farm address with Map & GPS.
class AddEditAddressSheet extends StatefulWidget {
  final UserAddress? initialAddress;
  final Future<String?> Function() onDetectGps;
  final ValueChanged<UserAddress> onSave;

  const AddEditAddressSheet({
    super.key,
    this.initialAddress,
    required this.onDetectGps,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    UserAddress? initialAddress,
    required Future<String?> Function() onDetectGps,
    required ValueChanged<UserAddress> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddEditAddressSheet(
        initialAddress: initialAddress,
        onDetectGps: onDetectGps,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditAddressSheet> createState() => _AddEditAddressSheetState();
}

class _AddEditAddressSheetState extends State<AddEditAddressSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedTag;
  late String _selectedCity;
  late final TextEditingController _addressLineController;
  late final TextEditingController _detailsController;
  late final TextEditingController _noteController;
  late bool _isDefault;
  LatLng? _pinnedPoint;
  bool _isGpsLoading = false;

  static const _tagOptions = ['სახლი', 'სამსახური', 'მეურნეობა', 'აგარაკი', 'სხვა'];
  static const _quickCities = ['თბილისი', 'ბათუმი', 'ქუთაისი', 'რუსთავი', 'თელავი'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialAddress;
    _selectedTag = init?.title ?? 'სახლი';
    _selectedCity = init?.city.isNotEmpty == true ? init!.city : 'თბილისი';
    _addressLineController = TextEditingController(text: init?.addressLine ?? '');
    _detailsController = TextEditingController(text: init?.details ?? '');
    _noteController = TextEditingController(text: init?.note ?? '');
    _isDefault = init?.isDefault ?? false;
    if (init?.latitude != null && init?.longitude != null) {
      _pinnedPoint = LatLng(init!.latitude!, init.longitude!);
    }
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _detailsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleGps() async {
    setState(() => _isGpsLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      final resolved = await GeorgianGeoLookup.resolveDetailedAddress(point);
      if (!mounted) return;
      setState(() {
        _pinnedPoint = point;
        _addressLineController.text = resolved;
        for (final city in _quickCities) {
          if (resolved.contains(city)) {
            _selectedCity = city;
            break;
          }
        }
      });
      AppToast.success(context, 'GPS-ით დადგინდა: $resolved');
    } catch (_) {
      final fallback = await widget.onDetectGps();
      if (!mounted) return;
      if (fallback != null && fallback.isNotEmpty) {
        setState(() => _addressLineController.text = fallback);
        AppToast.success(context, 'მდებარეობა დადგინდა: $fallback');
      } else {
        AppToast.error(context, 'GPS მდებარეობა ვერ დადგინდა');
      }
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  void _openMapPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FarmerMapWidget(
          isFullScreen: true,
          locationText: _addressLineController.text.isNotEmpty
              ? _addressLineController.text
              : 'თბილისი, საქართველო',
          initialLocation: _pinnedPoint,
          onLocationChanged: (point) {
            _pinnedPoint = point;
          },
          onAddressResolved: (point, address) {
            setState(() {
              _pinnedPoint = point;
              _addressLineController.text = address;
              for (final city in _quickCities) {
                if (address.contains(city)) {
                  _selectedCity = city;
                  break;
                }
              }
            });
            AppToast.success(context, 'რუკაზე არჩეულია: $address');
          },
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final line = _addressLineController.text.trim();
    final details = _detailsController.text.trim();
    final note = _noteController.text.trim();

    final address = UserAddress(
      id: widget.initialAddress?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      title: _selectedTag,
      city: _selectedCity,
      addressLine: line,
      details: details.isNotEmpty ? details : null,
      note: note.isNotEmpty ? note : null,
      isDefault: _isDefault,
      latitude: _pinnedPoint?.latitude ?? widget.initialAddress?.latitude,
      longitude: _pinnedPoint?.longitude ?? widget.initialAddress?.longitude,
      createdAt: widget.initialAddress?.createdAt ?? DateTime.now(),
    );

    widget.onSave(address);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
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
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialAddress != null
                          ? 'მისამართის რედაქტირება'
                          : 'ახალი მისამართის დამატება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Tag selection chips
                Text(
                  'მისამართის ტიპი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tagOptions.map((tag) {
                    final isSel = _selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedTag = tag),
                      labelStyle: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                        color: isSel ? AppColors.primaryDark : const Color(0xFF334155),
                      ),
                      selectedColor: AppColors.primaryLight,
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 2. City Chips
                Text(
                  'ქალაქი / რეგიონი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickCities.map((city) {
                      final isSel = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(city),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedCity = city),
                          labelStyle: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primaryDark : const Color(0xFF475569),
                          ),
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Address line input with GPS and Map buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ქუჩა და ნომერი',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // GPS Button
                        TextButton.icon(
                          onPressed: _isGpsLoading ? null : _handleGps,
                          icon: _isGpsLoading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.locateFixed, size: 14),
                          label: Text(
                            'GPS',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                        // Map Picker Button
                        TextButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(LucideIcons.map, size: 14),
                          label: Text(
                            'რუკაზე არჩევა',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextFormField(
                  controller: _addressLineController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'გთხოვთ მიუთითოთ ქუჩა და ნომერი';
                    }
                    return null;
                  },
                  style: GoogleFonts.notoSansGeorgian(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'მაგ: ი. ჭავჭავაძის გამზ. 24',
                    hintStyle: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _pinnedPoint != null
                        ? IconButton(
                            icon: const Icon(
                              LucideIcons.mapPinCheck,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            tooltip: 'რუკაზე ნახვა',
                            onPressed: _openMapPicker,
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Indicator if pinned on map
                if (_pinnedPoint != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.checkCheck, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ზუსტი კოორდინატები მონიშნულია (${_pinnedPoint!.latitude.toStringAsFixed(4)}, ${_pinnedPoint!.longitude.toStringAsFixed(4)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // 4. Details: Apartment / Entrance / Floor
                Text(
                  'დეტალები (სურვილისამებრ)',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _detailsController,
                  style: GoogleFonts.notoSansGeorgian(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'სადარბაზო, სართული, ბინის ნომერი',
                    hintStyle: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.building,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Courier note
                Text(
                  'კომენტარი კურიერისთვის (სურვილისამებრ)',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  style: GoogleFonts.notoSansGeorgian(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'მაგ: კოდი: 1234, დარეკეთ კარზე',
                    hintStyle: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.messageSquare,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 6. Default address switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val),
                  activeTrackColor: AppColors.primary,
                  title: Text(
                    'ძირითად მისამართად დაყენება',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'ავტომატურად შეირჩევა ყველა შეკვეთაზე',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Save CTA Button
                SizedBox(
                  height: 48,
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
                      'შენახვა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
