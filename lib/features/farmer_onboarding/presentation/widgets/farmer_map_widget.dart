import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
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
  'ხელვაჩაური': LatLng(41.5833, 41.6667), // Masaura/Akhalsheni area
  'მცხეთა': LatLng(41.8458, 44.7188),
  'დუშეთი': LatLng(42.0833, 44.7000),
  'ყაზბეგი': LatLng(42.6567, 44.6433),
  'თბილისი': LatLng(41.7151, 44.8271),
};

/// Custom Vector Teardrop Pin Painter for AgroKera
class AgroKeraPinPainter extends CustomPainter {
  final Color pinColor;
  final Color innerColor;

  const AgroKeraPinPainter({
    this.pinColor = AppColors.primary,
    this.innerColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft ground contact shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 1),
        width: 14,
        height: 5,
      ),
      shadowPaint,
    );

    // 2. Teardrop Pin Shape
    final radius = size.width / 2;
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        0.65,
        4.98,
      )
      ..lineTo(size.width / 2, size.height)
      ..close();

    // Fill pin
    final pinPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);

    // Crisp white outer border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // 3. Inner white circle
    final innerCirclePaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius * 0.54, innerCirclePaint);

    // 4. Center green target dot
    final centerDotPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius * 0.28, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Farm Pin Widget with label and custom teardrop pin
class CustomFarmPinWidget extends StatelessWidget {
  final String label;

  const CustomFarmPinWidget({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Floating Label Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.sprout, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),

        // Custom Vector Teardrop Pin
        CustomPaint(
          size: const Size(32, 42),
          painter: const AgroKeraPinPainter(),
        ),
      ],
    );
  }
}

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
  late LatLng _mapCenter;
  LatLng? _pinnedLocation;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinnedLocation = widget.initialLocation;
    _mapCenter = _pinnedLocation ?? _resolveDefaultCoordinates(widget.locationText);
  }

  @override
  void didUpdateWidget(covariant FarmerMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation) {
      setState(() {
        _pinnedLocation = widget.initialLocation;
        if (_pinnedLocation != null) {
          _mapCenter = _pinnedLocation!;
        }
      });
      if (_pinnedLocation != null) {
        _mapController.move(_pinnedLocation!, _currentZoom);
      }
    } else if (widget.locationText != oldWidget.locationText) {
      final resolved = _resolveDefaultCoordinates(widget.locationText);
      setState(() {
        _mapCenter = resolved;
      });
      _mapController.move(_mapCenter, _currentZoom);
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
    HapticFeedback.lightImpact();
    setState(() {
      _pinnedLocation = point;
    });
    widget.onLocationChanged?.call(point);
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

  void _recenter() {
    HapticFeedback.lightImpact();
    final target = _resolveDefaultCoordinates(widget.locationText);
    setState(() {
      _mapCenter = target;
      _currentZoom = 13.0;
    });
    _mapController.move(target, 13.0);
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

        // Custom Farmer Pin Marker (only rendered when user actually selected/marked a location)
        if (_pinnedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _pinnedLocation!,
                width: 140,
                height: 74,
                alignment: Alignment.topCenter,
                child: CustomFarmPinWidget(
                  label: widget.locationText,
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

              // 3. Top Header Bar
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

                        // Title indicator chip
                        Container(
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
                                _pinnedLocation != null ? LucideIcons.mapPinCheck : LucideIcons.mapPin,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _pinnedLocation != null
                                    ? 'ფერმის ლოკაცია მონიშნულია'
                                    : 'შეეხეთ რუკას მოსანიშნად',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Clear pin button if pinned, else balance spacer
                        if (_pinnedLocation != null)
                          InkWell(
                            onTap: () {
                              setState(() => _pinnedLocation = null);
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

              // 5. Bottom Confirm Button (Firmly anchored to bottom)
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
                          Text(
                            _pinnedLocation != null
                                ? 'ლოკაციის არჩევა'
                                : 'ცენტრის არჩევა',
                            style: const TextStyle(
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

              // Status chip (top left)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                      Text(
                        _pinnedLocation != null ? 'მონიშნულია' : 'მონიშნეთ რუკაზე',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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
