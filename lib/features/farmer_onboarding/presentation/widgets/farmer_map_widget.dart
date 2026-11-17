import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/georgian_geo_data.dart';
import '../../../../core/services/georgian_geo_lookup_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import 'custom_farm_pin_widget.dart';

export '../../../../core/constants/georgian_geo_data.dart';
export '../../../../core/services/georgian_geo_lookup_service.dart';
export 'custom_farm_pin_widget.dart';

/// OpenStreetMap / Leaflet interactive map widget for Farmer onboarding
class FarmerMapWidget extends StatefulWidget {
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;
  final String locationText;
  final LatLng? initialLocation;
  final ValueChanged<LatLng>? onLocationChanged;
  final void Function(LatLng point, String address)? onAddressResolved;

  const FarmerMapWidget({
    super.key,
    this.isFullScreen = false,
    this.onToggleFullScreen,
    this.locationText = 'კახეთი, გურჯაანი, 1 რაიონი',
    this.initialLocation,
    this.onLocationChanged,
    this.onAddressResolved,
  });

  @override
  State<FarmerMapWidget> createState() => _FarmerMapWidgetState();
}

class _FarmerMapWidgetState extends State<FarmerMapWidget> {
  late final MapController _mapController;
  late LatLng _mapCenter;
  LatLng? _pinnedLocation;
  late String _currentAddress;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinnedLocation = widget.initialLocation;
    _currentAddress = widget.locationText;

    if (_pinnedLocation != null) {
      _mapCenter = _pinnedLocation!;
      _currentAddress = GeorgianGeoLookup.resolveInstantAddress(_pinnedLocation!);
    } else {
      _mapCenter = _resolveDefaultCoordinates(widget.locationText);
    }
  }

  @override
  void didUpdateWidget(covariant FarmerMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation) {
      setState(() {
        _pinnedLocation = widget.initialLocation;
        if (_pinnedLocation != null) {
          _mapCenter = _pinnedLocation!;
          _currentAddress = GeorgianGeoLookup.resolveInstantAddress(_pinnedLocation!);
        }
      });
      if (_pinnedLocation != null) {
        _mapController.move(_pinnedLocation!, _currentZoom);
      }
    } else if (widget.locationText != oldWidget.locationText && _pinnedLocation == null) {
      final resolved = _resolveDefaultCoordinates(widget.locationText);
      setState(() {
        _mapCenter = resolved;
        _currentAddress = widget.locationText;
      });
      _mapController.move(_mapCenter, _currentZoom);
    }
  }

  LatLng _resolveDefaultCoordinates(String text) {
    for (final entry in kGeorgianSettlements) {
      if (text.contains(entry.name)) {
        return entry.coordinates;
      }
    }
    // Default to Gurjaani, Kakheti
    return const LatLng(41.7456, 45.7983);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    HapticFeedback.lightImpact();

    // 1. Instant spatial address resolution
    final quickAddress = GeorgianGeoLookup.resolveInstantAddress(point);

    setState(() {
      _pinnedLocation = point;
      _currentAddress = quickAddress;
    });

    widget.onLocationChanged?.call(point);
    widget.onAddressResolved?.call(point, quickAddress);

    // 2. Asynchronous online reverse geocoding refinement
    GeorgianGeoLookup.fetchNominatimAddress(point).then((onlineAddr) {
      if (!mounted) return;
      if (onlineAddr != null && _pinnedLocation == point) {
        setState(() {
          _currentAddress = onlineAddr;
        });
        widget.onAddressResolved?.call(point, onlineAddr);
      }
    });
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    });
    _mapController.move(_pinnedLocation ?? _mapCenter, _currentZoom);
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    });
    _mapController.move(_pinnedLocation ?? _mapCenter, _currentZoom);
  }

  Future<void> _recenter() async {
    HapticFeedback.lightImpact();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        AppToast.warning(context, 'გთხოვთ ჩართოთ GPS / მდებარეობის სერვისი');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          AppToast.error(
            context,
            'მდებარეობაზე წვდომის ნებართვა უარყოფილია',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        AppToast.error(
          context,
          'მდებარეობის ნებართვა დაბლოკილია. გთხოვთ ჩართოთ ბრაუზერის/ტელეფონის პარამეტრებიდან.',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;

      final gpsPoint = LatLng(pos.latitude, pos.longitude);
      final quickAddress = GeorgianGeoLookup.resolveInstantAddress(gpsPoint);

      setState(() {
        _pinnedLocation = gpsPoint;
        _mapCenter = gpsPoint;
        _currentAddress = quickAddress;
        _currentZoom = 15.0;
      });
      _mapController.move(gpsPoint, 15.0);
      widget.onLocationChanged?.call(gpsPoint);
      widget.onAddressResolved?.call(gpsPoint, quickAddress);

      AppToast.success(
        context,
        'თქვენი GPS მდებარეობა დადგენილია: $quickAddress',
        icon: LucideIcons.mapPinCheck,
      );

      GeorgianGeoLookup.fetchNominatimAddress(gpsPoint).then((onlineAddr) {
        if (!mounted) return;
        if (onlineAddr != null && _pinnedLocation == gpsPoint) {
          setState(() => _currentAddress = onlineAddr);
          widget.onAddressResolved?.call(gpsPoint, onlineAddr);
        }
      });
    } catch (_) {
      if (!mounted) return;
      final target =
          _pinnedLocation ?? _resolveDefaultCoordinates(widget.locationText);
      setState(() {
        _mapCenter = target;
        _currentZoom = 13.0;
      });
      _mapController.move(target, 13.0);
      AppToast.info(
        context,
        'GPS მდებარეობის მიღება ვერ მოხერხდა, შეამოწმეთ ნებართვა',
      );
    }
  }

  /// Show Full Address Modal Bottom Sheet when address pill or pin is tapped
  void _showAddressBottomSheet() {
    HapticFeedback.mediumImpact();
    final point = _pinnedLocation ?? widget.initialLocation ?? _mapCenter;
    final latStr = point.latitude.toStringAsFixed(4);
    final lngStr = point.longitude.toStringAsFixed(4);
    final addressText = _pinnedLocation != null
        ? _currentAddress
        : widget.locationText.isNotEmpty
            ? widget.locationText
            : 'კახეთი, გურჯაანი';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title row with Pin icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.mapPinCheck,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'სრული მისამართი',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addressText,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GPS Coordinates info card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.navigation, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'GPS კოორდინატები: $latStr° N, $lngStr° E',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons: Copy & Close
                Row(
                  children: [
                    // Copy button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: addressText));
                          Navigator.of(ctx).pop();
                          AppToast.success(
                            context,
                            'მისამართი დაკოპირდა!',
                            icon: LucideIcons.copyCheck,
                          );
                        },
                        icon: const Icon(LucideIcons.copy, size: 16),
                        label: const Text('კოპირება'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Close button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'გასაგებია',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pinnedLocation ?? _mapCenter,
        initialZoom: _currentZoom,
        minZoom: 3.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onTap: _onMapTap,
      ),
      children: [
        // Free OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ge.agrokera.app',
        ),

        // 1:1 Vector Barn Pin Marker (rendered when user tapped/placed pin)
        if (_pinnedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _pinnedLocation!,
                width: 190,
                height: 88,
                alignment: Alignment.topCenter,
                child: CustomFarmPinWidget(
                  label: _currentAddress,
                  onTap: _showAddressBottomSheet,
                ),
              ),
            ],
          ),
      ],
    );

    // Leaflet / OpenStreetMap attribution pill matching user's design
    final attributionBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 7,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF005BBB), Color(0xFFFFD500)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Leaflet | © OpenStreetMap contributors',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0078A8),
            ),
          ),
        ],
      ),
    );

    // ==========================================
    // FULLSCREEN MAP VIEW
    // ==========================================
    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Interactive Fullscreen OpenStreetMap
              Positioned.fill(child: mapWidget),

              // 2. Leaflet / OpenStreetMap attribution badge
              Positioned(
                left: 12,
                bottom: 84,
                child: attributionBadge,
              ),

              // 3. Top Header Bar with Dynamic Address Pill
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back / Close Button
                        InkWell(
                          onTap: widget.onToggleFullScreen ?? () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Dynamic Address indicator chip on top (tap to view full address)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showAddressBottomSheet,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                      Icon(
                                        _pinnedLocation != null
                                            ? LucideIcons.mapPinCheck
                                            : LucideIcons.mapPin,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _pinnedLocation != null
                                              ? _currentAddress
                                              : 'შეეხეთ რუკას მოსანიშნად',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (_pinnedLocation != null) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          LucideIcons.chevronDown,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Clear pin button if pinned, else balance spacer
                        if (_pinnedLocation != null)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _pinnedLocation = null;
                                _currentAddress = widget.locationText;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.rotateCcw,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 42),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Zoom & Recenter Controls
              Positioned(
                right: 16,
                bottom: 84,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_recenter',
                      backgroundColor: Colors.white,
                      elevation: 3,
                      onPressed: _recenter,
                      child: const Icon(LucideIcons.crosshair, color: AppColors.textPrimary, size: 18),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      backgroundColor: Colors.white,
                      elevation: 3,
                      onPressed: _zoomIn,
                      child: const Icon(LucideIcons.plus, color: AppColors.textPrimary, size: 18),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      backgroundColor: Colors.white,
                      elevation: 3,
                      onPressed: _zoomOut,
                      child: const Icon(LucideIcons.minus, color: AppColors.textPrimary, size: 18),
                    ),
                  ],
                ),
              ),

              // 5. Bottom Confirm Button
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final chosen = _pinnedLocation ?? _mapCenter;
                        widget.onLocationChanged?.call(chosen);
                        widget.onAddressResolved?.call(chosen, _currentAddress);
                        if (widget.onToggleFullScreen != null) {
                          widget.onToggleFullScreen!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.check, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _pinnedLocation != null
                                  ? 'ლოკაციის არჩევა ($_currentAddress)'
                                  : 'ცენტრის არჩევა',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================
    // IN-CARD MAP PREVIEW
    // ==========================================
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: mapWidget),

              // Dynamic Status Chip (top left - tap to view full address)
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddressBottomSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _pinnedLocation != null ? LucideIcons.mapPinCheck : LucideIcons.mapPin,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              _pinnedLocation != null ? _currentAddress : 'მონიშნეთ რუკაზე',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_pinnedLocation != null) ...[
                            const SizedBox(width: 3),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 11,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // GPS Recenter Button (top right, left of maximize)
              Positioned(
                top: 8,
                right: 46,
                child: InkWell(
                  onTap: _recenter,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.crosshair,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Maximize / Fullscreen toggle button (top right)
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: widget.onToggleFullScreen,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.maximize2,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Attribution badge (bottom right)
              Positioned(
                bottom: 6,
                right: 6,
                child: attributionBadge,
              ),

              // Floating Tap Hint if not yet pinned
              if (_pinnedLocation == null)
                Center(
                  child: GestureDetector(
                    onTap: widget.onToggleFullScreen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.touchpad, size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'შეეხეთ რუკას მოსანიშნად',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
