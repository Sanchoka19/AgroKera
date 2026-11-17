import 'package:flutter/material.dart';
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
  LatLng? _pinnedLocation;
  bool _isGpsLoading = false;

  static const _quickRegions = [
    'კახეთი',
    'შიდა ქართლი',
    'იმერეთი',
    'სამეგრელო',
    'ქვემო ქართლი',
    'მცხეთა-მთიანეთი',
    'გურია',
    'აჭარა',
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authStateProvider);
    final fid = widget.farmerId ?? auth.farmerId ?? 'farmer_1';
    final farmers = ref.read(marketplaceProvider).farmers;
    final farmer = farmers.where((f) => f.id == fid).firstOrNull;

    final initialText = farmer?.location.isNotEmpty == true
        ? farmer!.location
        : 'კახეთი, გურჯაანი, 1 რაიონი';

    _locationController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _locationController.dispose();
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
      final resolved = GeorgianGeoLookup.resolveInstantAddress(point);
      if (!mounted) return;
      setState(() {
        _pinnedLocation = point;
        _locationController.text = resolved;
      });
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

    final auth = ref.read(authStateProvider);
    final fid = widget.farmerId ?? auth.farmerId ?? 'farmer_1';

    // 1. Update live marketplace state (so all clients immediately see updated location)
    ref.read(marketplaceProvider.notifier).updateFarmerLocation(
          farmerId: fid,
          location: clean,
        );

    // 2. Persist locally in secure storage
    await ref.read(secureStorageProvider).saveFarmLocation(clean);

    if (!mounted) return;
    AppToast.success(context, 'ფერმის მისამართი წარმატებით განახლდა!');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final fid = widget.farmerId ?? auth.farmerId ?? 'farmer_1';
    final farmers = ref.watch(marketplaceProvider).farmers;
    final farmer = farmers.where((f) => f.id == fid).firstOrNull;

    final farmName = farmer?.farmName ?? auth.farmName ?? 'ჩემი მეურნეობა';
    final currentLocation = farmer?.location ?? _locationController.text;

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Public Farm Info Card
            FarmAddressInfoCard(
              farmName: farmName,
              location: currentLocation,
              onEdit: _openMapPicker,
            ),
            const SizedBox(height: 16),

            // 2. Interactive Map Launch Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'რუკაზე მონიშვნა',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(LucideIcons.map, size: 14),
                        label: Text(
                          'რუკის გახსნა',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Map banner click trigger
                  InkWell(
                    onTap: _openMapPicker,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&auto=format&fit=crop&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'დააჭირეთ რუკაზე წერტილის შესარჩევად',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_pinnedLocation != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCheck,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'კოორდინატები მონიშნულია: ${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Quick Regions Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'სწრაფი რეგიონი',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickRegions.map((region) {
                      final isSelected =
                          _locationController.text.contains(region);
                      return FilterChip(
                        label: Text(region),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            final current = _locationController.text;
                            if (!current.contains(region)) {
                              _locationController.text = '$region, $current';
                            }
                          });
                        },
                        labelStyle: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryDark
                              : const Color(0xFF475569),
                        ),
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // 4. Exact Address Line Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'მეურნეობის ზუსტი მისამართი',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.locateFixed, size: 14),
                        label: Text(
                          'GPS ლოკაცია',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _locationController,
                    style: GoogleFonts.notoSansGeorgian(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'მაგ: კახეთი, გურჯაანი, სოფ. ვაზისუბანი',
                      hintStyle: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.tractor,
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveFarmLocation,
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(
                'ფერმის მისამართის შენახვა',
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
    );
  }
}
