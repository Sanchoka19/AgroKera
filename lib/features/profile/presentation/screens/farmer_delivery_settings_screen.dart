import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import '../../../marketplace/data/models/farmer_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';

/// Screen allowing farmers to configure and update their delivery options,
/// covered regions, custom fees per region, delivery schedule, and self-pickup.
class FarmerDeliverySettingsScreen extends ConsumerStatefulWidget {
  final String? farmerId;

  const FarmerDeliverySettingsScreen({super.key, this.farmerId});

  @override
  ConsumerState<FarmerDeliverySettingsScreen> createState() =>
      _FarmerDeliverySettingsScreenState();
}

class _FarmerDeliverySettingsScreenState
    extends ConsumerState<FarmerDeliverySettingsScreen> {
  late bool _isDeliveryEnabled;
  late Map<String, double> _regionalFees;
  late List<String> _selectedDays;
  late TextEditingController _locationController;
  bool _isLocatingGps = false;

  static const Map<String, String> _shortToFullDay = {
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

  static String _normalizeDay(String d) => _shortToFullDay[d.trim()] ?? d.trim();

  static const List<String> _allWeekdays = [
    'ორშაბათი',
    'სამშაბათი',
    'ოთხშაბათი',
    'ხუთშაბათი',
    'პარასკევი',
    'შაბათი',
    'კვირა',
  ];

  static const List<String> _popularCities = [
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
  void initState() {
    super.initState();
    final marketplace = ref.read(marketplaceProvider);
    final authState = ref.read(authStateProvider);
    final targetId = widget.farmerId ?? authState.farmerId ?? 'farmer_2';

    final farmer = marketplace.farmers.firstWhere(
      (f) => f.id == targetId,
      orElse: () => marketplace.farmers.isNotEmpty
          ? marketplace.farmers.first
          : FarmerModel(
              id: targetId,
              farmName: authState.farmName ?? 'ჩემი მეურნეობა',
              farmerName: authState.userName ?? 'ფერმერი',
              location: 'საქართველო',
              rating: 5.0,
              reviewCount: 0,
              totalRatings: 0,
              isVerified: true,
              isVatPayer: false,
              avatarUrl: authState.userAvatarUrl ?? '',
              coverUrl: authState.farmCoverUrl ?? '',
              about: '',
              phone: authState.userPhone ?? '',
            ),
    );

    _isDeliveryEnabled = farmer.isDeliveryEnabled;
    _regionalFees = Map<String, double>.from(
      farmer.regionalDeliveryFees.isNotEmpty
          ? farmer.regionalDeliveryFees
          : {farmer.deliveryCity: farmer.deliveryFee},
    );
    _selectedDays = farmer.deliveryDays
        .map(_normalizeDay)
        .toSet()
        .toList();
    if (_selectedDays.isEmpty) {
      _selectedDays = ['შაბათი'];
    }
    _locationController = TextEditingController(text: farmer.location);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _determineCurrentGpsLocation() async {
    setState(() => _isLocatingGps = true);
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
      final resolved = GeorgianGeoLookup.resolveInstantAddress(
        LatLng(pos.latitude, pos.longitude),
      );
      if (!mounted) return;
      setState(() {
        _locationController.text = resolved;
      });
      AppToast.success(context, 'მდებარეობა დადგინდა: $resolved');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'GPS მდებარეობის დადგენა ვერ მოხერხდა');
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  void _openAddRegionSheet() {
    final cityController = TextEditingController();
    final feeController = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
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
                        onPressed: () => Navigator.pop(sheetContext),
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
                    children: _popularCities
                        .where((c) => !_regionalFees.containsKey(c))
                        .map(
                          (city) => GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                cityController.text = city;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cityController.text == city
                                    ? AppColors.primaryLight
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cityController.text == city
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                city,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 12,
                                  fontWeight: cityController.text == city
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: cityController.text == city
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
                    controller: cityController,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText: 'მაგ. თბილისი, გორი, ქუთაისი...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      suffixIcon: cityController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () => setSheetState(() => cityController.clear()),
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
                          double.tryParse(feeController.text) == preset;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            feeController.text = preset.toInt().toString();
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
                    controller: feeController,
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
                      onPressed: () {
                        final city = cityController.text.trim();
                        final fee = double.tryParse(feeController.text.trim()) ?? 10.0;

                        if (city.isEmpty) {
                          AppToast.error(sheetContext, 'მიუთითეთ რეგიონის / ქალაქის სახელი');
                          return;
                        }

                        setState(() {
                          _regionalFees[city] = fee;
                        });

                        Navigator.pop(sheetContext);
                        AppToast.success(context, 'რეგიონი "$city" დაემატა ($fee ₾)');
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
        },
      ),
    );
  }

  FarmerModel _resolveFarmer() {
    final marketplace = ref.read(marketplaceProvider);
    final authState = ref.read(authStateProvider);
    final targetId = widget.farmerId ?? authState.farmerId ?? 'farmer_2';

    return marketplace.farmers.firstWhere(
      (f) => f.id == targetId,
      orElse: () => marketplace.farmers.isNotEmpty
          ? marketplace.farmers.first
          : FarmerModel(
              id: targetId,
              farmName: authState.farmName ?? 'ჩემი მეურნეობა',
              farmerName: authState.userName ?? 'ფერმერი',
              location: 'საქართველო',
              rating: 5.0,
              reviewCount: 0,
              totalRatings: 0,
              isVerified: true,
              isVatPayer: false,
              avatarUrl: authState.userAvatarUrl ?? '',
              coverUrl: authState.farmCoverUrl ?? '',
              about: '',
              phone: authState.userPhone ?? '',
            ),
    );
  }

  void _saveSettings() {
    if (_isDeliveryEnabled) {
      if (_regionalFees.isEmpty) {
        AppToast.error(
          context,
          'გთხოვთ დაამატოთ მინიმუმ ერთი მიტანის რეგიონი',
        );
        return;
      }
      if (_selectedDays.isEmpty) {
        AppToast.error(
          context,
          'გთხოვთ მონიშნოთ მინიმუმ ერთი მიტანის დღე',
        );
        return;
      }
    }

    final farmer = _resolveFarmer();
    final authState = ref.read(authStateProvider);
    final primaryCity =
        _regionalFees.keys.isNotEmpty ? _regionalFees.keys.first : 'თბილისი';
    final primaryFee =
        _regionalFees.values.isNotEmpty ? _regionalFees.values.first : 7.0;

    final shouldUpdateAllDemo =
        authState.farmerId == null || widget.farmerId == null;

    ref.read(marketplaceProvider.notifier).updateFarmerDeliverySettings(
          farmerId: farmer.id,
          isDeliveryEnabled: _isDeliveryEnabled,
          deliveryCity: primaryCity,
          deliveryDays: _selectedDays,
          deliveryFee: primaryFee,
          regionalDeliveryFees: _regionalFees,
          isPickupEnabled: true,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : farmer.location,
          updateAllDemoFarmers: shouldUpdateAllDemo,
        );

    if (authState.farmerId != null && authState.farmerId != farmer.id) {
      ref.read(marketplaceProvider.notifier).updateFarmerDeliverySettings(
            farmerId: authState.farmerId!,
            isDeliveryEnabled: _isDeliveryEnabled,
            deliveryCity: primaryCity,
            deliveryDays: _selectedDays,
            deliveryFee: primaryFee,
            regionalDeliveryFees: _regionalFees,
            isPickupEnabled: true,
            location: _locationController.text.trim().isNotEmpty
                ? _locationController.text.trim()
                : farmer.location,
            updateAllDemoFarmers: false,
          );
    }

    AppToast.success(context, 'მიწოდების პარამეტრები წარმატებით განახლდა!');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'მიწოდების პარამეტრები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // CARD 1: საკურიერო მიტანის ჩამრთველი
            // ==========================================
            Container(
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
                          color: _isDeliveryEnabled
                              ? AppColors.primaryLight
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.truck,
                          color: _isDeliveryEnabled
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
                              _isDeliveryEnabled
                                  ? 'მიტანის სერვისი აქტიურია'
                                  : 'მიტანა გამორთულია',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12.5,
                                color: _isDeliveryEnabled
                                    ? AppColors.primaryDark
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDeliveryEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _isDeliveryEnabled = val);
                        },
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
            ),
            const SizedBox(height: 14),

            // ==========================================
            // CARD 2: დაფარვის ზონები და რეგიონალური ტარიფები
            // ==========================================
            if (_isDeliveryEnabled) ...[
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'დაფარვის ზონები',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _openAddRegionSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.plus,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'დამატება',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'მიუთითეთ ქალაქები/რეგიონები, სადაც მიგაქვთ პროდუქცია და მიტანის საფასური (0 ₾ = უფასო მიტანა):',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // List of current regions
                    if (_regionalFees.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'რეგიონები ჯერ არ არის დამატებული. გთხოვთ დაამატოთ მინიმუმ ერთი რეგიონი.',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      ..._regionalFees.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.value == 0
                                      ? 'უფასო'
                                      : '${entry.value.toInt()} ₾',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  size: 16,
                                  color: Color(0xFFEF4444),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _regionalFees.remove(entry.key);
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ==========================================
              // CARD 3: მიტანის დღეების გრაფიკი
              // ==========================================
              Container(
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
                      children: _allWeekdays.map((day) {
                        final normalizedDay = _normalizeDay(day);
                        final isSelected = _selectedDays.any(
                          (d) => _normalizeDay(d) == normalizedDay,
                        );
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (!_selectedDays.any(
                                    (d) => _normalizeDay(d) == normalizedDay)) {
                                  _selectedDays.add(normalizedDay);
                                }
                              } else {
                                _selectedDays.removeWhere(
                                    (d) => _normalizeDay(d) == normalizedDay);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedDays.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'აქტიური გრაფიკი: ${_allWeekdays.where((d) => _selectedDays.any((sd) => _normalizeDay(sd) == d)).join(", ")}',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ==========================================
            // CARD 4: თვითგატანა მეურნეობიდან (მუდმივად აქტიური)
            // ==========================================
            Container(
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
                    controller: _locationController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'ჩემი მდებარეობის დადგენა (GPS)',
                        icon: _isLocatingGps
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
                        onPressed: _isLocatingGps
                            ? null
                            : _determineCurrentGpsLocation,
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'ცვლილებების შენახვა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
