import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/services/georgian_geo_lookup_service.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import '../widgets/delivery_settings/add_region_bottom_sheet.dart';
import '../widgets/delivery_settings/delivery_courier_toggle_card.dart';
import '../widgets/delivery_settings/delivery_days_schedule_card.dart';
import '../widgets/delivery_settings/delivery_zones_card.dart';
import '../widgets/delivery_settings/farm_pickup_address_card.dart';

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
        .map(DeliveryDaysScheduleCard.normalizeDay)
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
    AddRegionBottomSheet.show(
      context,
      existingRegions: _regionalFees.keys.toSet(),
      onRegionAdded: (city, fee) {
        setState(() {
          _regionalFees[city] = fee;
        });
        AppToast.success(context, 'რეგიონი "$city" დაემატა ($fee ₾)');
      },
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
            DeliveryCourierToggleCard(
              isDeliveryEnabled: _isDeliveryEnabled,
              onToggle: (val) => setState(() => _isDeliveryEnabled = val),
            ),
            const SizedBox(height: 14),
            if (_isDeliveryEnabled) ...[
              DeliveryZonesCard(
                regionalFees: _regionalFees,
                onAddRegion: _openAddRegionSheet,
                onRemoveRegion: (city) {
                  setState(() => _regionalFees.remove(city));
                },
              ),
              const SizedBox(height: 14),
              DeliveryDaysScheduleCard(
                selectedDays: _selectedDays,
                onDaysChanged: (days) {
                  setState(() => _selectedDays = days);
                },
              ),
              const SizedBox(height: 14),
            ],
            FarmPickupAddressCard(
              locationController: _locationController,
              isLocatingGps: _isLocatingGps,
              onGpsLocate: _determineCurrentGpsLocation,
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
