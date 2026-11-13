import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Predefined coordinates for major Georgian cities/regions
const Map<String, LatLng> kGeorgianCityCoordinates = {
  'გურჯაანი': LatLng(41.7456, 45.7983),
  'თელავი': LatLng(41.9198, 45.4731),
  'ყვარელი': LatLng(41.9547, 45.8153),
  'საგარეჯო': LatLng(41.7333, 45.3333),
  'სიღნაღი': LatLng(41.6212, 45.9214),
  'ახმეტა': LatLng(42.0333, 45.2167),
  'ქუთაისი': LatLng(42.2679, 42.6946),
  'სამტრედია': LatLng(42.1625, 42.3417),
  'ზესტაფონი': LatLng(42.1089, 43.0336),
  'წყალტუბო': LatLng(42.3267, 42.5997),
  'გორი': LatLng(41.9842, 44.1158),
  'კასპი': LatLng(41.9250, 44.4250),
  'ხაშური': LatLng(41.9967, 43.5986),
  'ქარელი': LatLng(42.0231, 43.8944),
  'რუსთავი': LatLng(41.5495, 45.0186),
  'მარნეული': LatLng(41.4747, 44.8089),
  'ბოლნისი': LatLng(41.4489, 44.5381),
  'ზუგდიდი': LatLng(42.5088, 41.8709),
  'ფოთი': LatLng(42.1462, 41.6720),
  'სენაკი': LatLng(42.2689, 42.0678),
  'ოზურგეთი': LatLng(41.9269, 42.0006),
  'ლანჩხუთი': LatLng(42.0875, 42.0361),
  'ჩოხატაური': LatLng(42.0189, 42.2394),
  'ბათუმი': LatLng(41.6168, 41.6367),
  'ქობულეთი': LatLng(41.8214, 41.7792),
  'ხელვაჩაური': LatLng(41.5833, 41.6667), // Masaura/Akhalsheni/Sameba area
  'მცხეთა': LatLng(41.8458, 44.7188),
  'დუშეთი': LatLng(42.0833, 44.7000),
  'ყაზბეგი': LatLng(42.6567, 44.6433),
  'თბილისი': LatLng(41.7151, 44.8271),
};

/// OpenStreetMap / Leaflet interactive map widget for Farmer onboarding
class FarmerMapWidget extends StatefulWidget {
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;
  final String locationText;
  final LatLng? initialLocation;
  final ValueChanged<LatLng>? onLocationChanged;

  const FarmerMapWidget({
    super.key,
    this.isFullScreen = false,
    this.onToggleFullScreen,
    this.locationText = 'კახეთი, გურჯაანი, 1 რაიონი',
    this.initialLocation,
    this.onLocationChanged,
  });

  @override
  State<FarmerMapWidget> createState() => _FarmerMapWidgetState();
}

class _FarmerMapWidgetState extends State<FarmerMapWidget> {
  late final MapController _mapController;
  late LatLng _currentLocation;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialLocation ??
        _resolveDefaultCoordinates(widget.locationText);
  }

  @override
  void didUpdateWidget(covariant FarmerMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != null &&
        widget.initialLocation != oldWidget.initialLocation) {
      setState(() {
        _currentLocation = widget.initialLocation!;
      });
      _mapController.move(_currentLocation, _currentZoom);
    } else if (widget.locationText != oldWidget.locationText) {
      final resolved = _resolveDefaultCoordinates(widget.locationText);
      setState(() {
        _currentLocation = resolved;
      });
      _mapController.move(_currentLocation, _currentZoom);
    }
  }

  LatLng _resolveDefaultCoordinates(String text) {
    for (final entry in kGeorgianCityCoordinates.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    // Default to Gurjaani, Kakheti
    return const LatLng(41.7456, 45.7983);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _currentLocation = point;
    });
    widget.onLocationChanged?.call(point);
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    });
    _mapController.move(_currentLocation, _currentZoom);
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    });
    _mapController.move(_currentLocation, _currentZoom);
  }

  void _recenter() {
    final target = _resolveDefaultCoordinates(widget.locationText);
    setState(() {
      _currentLocation = target;
      _currentZoom = 13.0;
    });
    _mapController.move(target, 13.0);
    widget.onLocationChanged?.call(target);
  }

  @override
  Widget build(BuildContext context) {
    final mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation,
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
          tileBuilder: (context, tileWidget, tile) {
            return tileWidget;
          },
        ),

        // Farmer Sprout Pin Marker
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation,
              width: 160,
              height: 72,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sprout, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    LucideIcons.mapPin,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ],
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

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(child: mapWidget),

            // Attribution badge at bottom-left
            Positioned(
              left: 12,
              bottom: 84,
              child: attributionBadge,
            ),

            // Top Header Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'მონიშნეთ ფერმის ლოკაცია',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 42), // Balance row
                  ],
                ),
              ),
            ),

            // Zoom & Recenter Controls
            Positioned(
              right: 16,
              bottom: 96,
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

            // Bottom Confirm Button
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onLocationChanged?.call(_currentLocation);
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
                      children: const [
                        Icon(LucideIcons.check, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'ლოკაციის არჩევა',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
      );
    }

    // In-Card Map Preview
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(child: mapWidget),

              // Current Address indicator pill (top left)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.navigation, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'მიმდინარე მისამართი',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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

              // Leaflet & OpenStreetMap attribution badge (bottom right)
              Positioned(
                bottom: 6,
                right: 6,
                child: attributionBadge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
