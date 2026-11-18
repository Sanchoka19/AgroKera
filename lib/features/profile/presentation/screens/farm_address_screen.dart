import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/storage/secure_storage_service.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import '../widgets/farm_address/farm_address_info_card.dart';

/// Screen allowing farmers to manage their public farm location & pickup point.
class FarmAddressScreen extends ConsumerStatefulWidget {
  final String? farmerId;

  const FarmAddressScreen({
    super.key,
    this.farmerId,
  });

  @override
  ConsumerState<FarmAddressScreen> createState() => _FarmAddressScreenState();
}

class _FarmAddressScreenState extends ConsumerState<FarmAddressScreen> {
  late final TextEditingController _locationController;
  late final TextEditingController _landmarkController;
  final MapController _miniMapController = MapController();
  LatLng? _pinnedLocation;
  bool _isGpsLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authStateProvider);
    final fid = widget.farmerId ?? auth.farmerId ?? 'farmer_1';
    final farmers = ref.read(marketplaceProvider).farmers;
    final farmer = farmers.where((f) => f.id == fid).firstOrNull;

    final initialText = farmer?.location.isNotEmpty == true
        ? farmer!.location
        : 'კახეთი, გურჯაანი, სოფ. ვაზისუბანი';

    _locationController = TextEditingController(text: initialText);
    _landmarkController = TextEditingController();

    _resolveInitialLocation(initialText);
    _loadSavedLandmark();
  }

  void _resolveInitialLocation(String text) {
    for (final entry in kGeorgianSettlements) {
      if (text.contains(entry.name)) {
        _pinnedLocation = entry.coordinates;
        return;
      }
    }
    // Default fallback coordinates: Gurjaani, Kakheti
    _pinnedLocation = const LatLng(41.7456, 45.7983);
  }

  Future<void> _loadSavedLandmark() async {
    final savedLandmark = await ref.read(secureStorageProvider).readFarmLandmark();
    if (savedLandmark != null && savedLandmark.isNotEmpty && mounted) {
      setState(() {
        _landmarkController.text = savedLandmark;
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _handleGps() async {
    setState(() => _isGpsLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (!mounted) return;
          AppToast.error(context, 'მდებარეობაზე წვდომა უარყოფილია');
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      final resolved = await GeorgianGeoLookup.resolveDetailedAddress(point);
      if (!mounted) return;
      setState(() {
        _pinnedLocation = point;
        _locationController.text = resolved;
      });
      _miniMapController.move(point, 13.5);
      AppToast.success(context, 'ფერმის ლოკაცია დადგინდა: $resolved');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'GPS ლოკაციის დადგენა ვერ მოხერხდა');
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
          locationText: _locationController.text.isNotEmpty
              ? _locationController.text
              : 'კახეთი, გურჯაანი',
          initialLocation: _pinnedLocation,
          onLocationChanged: (point) {
            _pinnedLocation = point;
          },
          onAddressResolved: (point, address) {
            setState(() {
              _pinnedLocation = point;
              _locationController.text = address;
            });
            _miniMapController.move(point, 13.5);
            AppToast.success(context, 'რუკაზე მონიშნულია: $address');
          },
        ),
      ),
    );
  }

  Future<void> _saveFarmLocation() async {
    final clean = _locationController.text.trim();
    if (clean.isEmpty) {
      AppToast.error(context, 'გთხოვთ მიუთითოთ ფერმის მისამართი');
      return;
    }

    setState(() => _isSaving = true);

    final auth = ref.read(authStateProvider);
    final fid = widget.farmerId ?? auth.farmerId ?? 'farmer_1';
    final landmark = _landmarkController.text.trim();

    try {
      // 1. Update live marketplace state (so clients immediately see updated location)
      ref.read(marketplaceProvider.notifier).updateFarmerLocation(
            farmerId: fid,
            location: clean,
          );

      // 2. Persist locally in secure storage
      await Future.wait([
        ref.read(secureStorageProvider).saveFarmLocation(clean),
        if (landmark.isNotEmpty)
          ref.read(secureStorageProvider).saveFarmLandmark(landmark),
      ]);

      if (!mounted) return;
      AppToast.success(context, 'ფერმის ლოკაცია წარმატებით შეინახა!');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'შენახვისას დაფიქსირდა შეცდომა');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final fid = widget.farmerId ?? auth.farmerId ?? 'farmer_1';
    final farmers = ref.watch(marketplaceProvider).farmers;
    final farmer = farmers.where((f) => f.id == fid).firstOrNull;

    final farmName = farmer?.farmName ?? auth.farmName ?? 'ჩემი მეურნეობა';
    final currentLocation = farmer?.location ?? _locationController.text;
    final mapCenter = _pinnedLocation ?? const LatLng(41.7456, 45.7983);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ფერმის მისამართი',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Public Farm Info Card (Storefront Preview)
            FarmAddressInfoCard(
              farmName: farmName,
              location: currentLocation,
              landmark: _landmarkController.text,
              onEdit: _openMapPicker,
            ),
            const SizedBox(height: 18),

            // 2. Clean Interactive Live Mini Map (No fake atlas images!)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.map,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'მდებარეობა რუკაზე',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        // Fullscreen map button
                        TextButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(LucideIcons.expand, size: 14),
                          label: Text(
                            'გაშლა',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Real OpenStreetMap Preview Widget
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      height: 180,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _miniMapController,
                            options: MapOptions(
                              initialCenter: mapCenter,
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none, // Disable scroll capture
                              ),
                              onTap: (_, _) => _openMapPicker(),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'ge.agrokera.app',
                              ),
                              if (_pinnedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _pinnedLocation!,
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          LucideIcons.tractor,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Tap to pick overlay button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'წერტილის შეცვლა',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // GPS Coordinates chip
                  if (_pinnedLocation != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.checkCheck,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'კოორდინატები: ${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Clear Address Form (Eliminating the confusing quick-region stack!)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form header with 1-Click GPS button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'მეურნეობის ზუსტი მისამართი',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isGpsLoading ? null : _handleGps,
                        icon: _isGpsLoading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(LucideIcons.locateFixed, size: 14),
                        label: Text(
                          'ჩემი GPS ლოკაცია',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Main Address input field
                  TextFormField(
                    controller: _locationController,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'მაგ: კახეთი, გურჯაანი, სოფ. ვაზისუბანი',
                      hintStyle: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
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
                  const SizedBox(height: 16),

                  // Landmark input field (Crucial for rural farm pickup!)
                  Text(
                    'ორიენტირი / როგორ მოვიდეთ (არასავალდებულო)',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _landmarkController,
                    maxLines: 2,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13.5,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'მაგ: სოფლის ცენტრთან, ყვითელი ჭიშკარი, მეურნეობა #3',
                      hintStyle: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(
                          LucideIcons.signpost,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveFarmLocation,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.check, size: 18),
                label: Text(
                  _isSaving ? 'ინახება...' : 'ფერმის მისამართის შენახვა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

