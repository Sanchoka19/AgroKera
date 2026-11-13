import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Predefined coordinates and metadata for Georgian settlements and municipalities
class GeorgianGeoEntry {
  final String name;
  final String region;
  final LatLng coordinates;

  const GeorgianGeoEntry({
    required this.name,
    required this.region,
    required this.coordinates,
  });
}

/// Comprehensive Georgian spatial database for instant, zero-latency reverse geocoding
const List<GeorgianGeoEntry> kGeorgianSettlements = [
  // კახეთი (Kakheti)
  GeorgianGeoEntry(name: 'გურჯაანი', region: 'კახეთი', coordinates: LatLng(41.7456, 45.7983)),
  GeorgianGeoEntry(name: 'თელავი', region: 'კახეთი', coordinates: LatLng(41.9198, 45.4731)),
  GeorgianGeoEntry(name: 'ყვარელი', region: 'კახეთი', coordinates: LatLng(41.9547, 45.8153)),
  GeorgianGeoEntry(name: 'სიღნაღი', region: 'კახეთი', coordinates: LatLng(41.6212, 45.9214)),
  GeorgianGeoEntry(name: 'საგარეჯო', region: 'კახეთი', coordinates: LatLng(41.7333, 45.3333)),
  GeorgianGeoEntry(name: 'ახმეტა', region: 'კახეთი', coordinates: LatLng(42.0333, 45.2167)),
  GeorgianGeoEntry(name: 'დედოფლისწყარო', region: 'კახეთი', coordinates: LatLng(41.4667, 46.1000)),
  GeorgianGeoEntry(name: 'ლაგოდეხი', region: 'კახეთი', coordinates: LatLng(41.8267, 46.2789)),
  GeorgianGeoEntry(name: 'წნორი', region: 'კახეთი', coordinates: LatLng(41.6117, 45.9733)),
  GeorgianGeoEntry(name: 'ველისციხე', region: 'კახეთი', coordinates: LatLng(41.8167, 45.7667)),
  GeorgianGeoEntry(name: 'წინანდალი', region: 'კახეთი', coordinates: LatLng(41.8953, 45.5714)),
  GeorgianGeoEntry(name: 'შილდა', region: 'კახეთი', coordinates: LatLng(42.0000, 45.7167)),

  // აჭარა (Adjara)
  GeorgianGeoEntry(name: 'ბათუმი', region: 'აჭარა', coordinates: LatLng(41.6168, 41.6367)),
  GeorgianGeoEntry(name: 'ქობულეთი', region: 'აჭარა', coordinates: LatLng(41.8214, 41.7792)),
  GeorgianGeoEntry(name: 'ხელვაჩაური', region: 'აჭარა', coordinates: LatLng(41.5833, 41.6667)),
  GeorgianGeoEntry(name: 'ახალშენი', region: 'ხელვაჩაური', coordinates: LatLng(41.6033, 41.6917)),
  GeorgianGeoEntry(name: 'მასაურა', region: 'ხელვაჩაური', coordinates: LatLng(41.6120, 41.7100)),
  GeorgianGeoEntry(name: 'სამება', region: 'ხელვაჩაური', coordinates: LatLng(41.6322, 41.6950)),
  GeorgianGeoEntry(name: 'ჩაქვი', region: 'ქობულეთი', coordinates: LatLng(41.7244, 41.7314)),
  GeorgianGeoEntry(name: 'მახინჯაური', region: 'ხელვაჩაური', coordinates: LatLng(41.6742, 41.6947)),
  GeorgianGeoEntry(name: 'ქედა', region: 'აჭარა', coordinates: LatLng(41.6000, 41.9333)),
  GeorgianGeoEntry(name: 'შუახევი', region: 'აჭარა', coordinates: LatLng(41.6256, 42.1856)),
  GeorgianGeoEntry(name: 'ხულო', region: 'აჭარა', coordinates: LatLng(41.6444, 42.3167)),
  GeorgianGeoEntry(name: 'გონიო', region: 'ხელვაჩაური', coordinates: LatLng(41.5736, 41.5722)),
  GeorgianGeoEntry(name: 'სარფი', region: 'ხელვაჩაური', coordinates: LatLng(41.5219, 41.5519)),

  // იმერეთი (Imereti)
  GeorgianGeoEntry(name: 'ქუთაისი', region: 'იმერეთი', coordinates: LatLng(42.2679, 42.6946)),
  GeorgianGeoEntry(name: 'სამტრედია', region: 'იმერეთი', coordinates: LatLng(42.1625, 42.3417)),
  GeorgianGeoEntry(name: 'ზესტაფონი', region: 'იმერეთი', coordinates: LatLng(42.1089, 43.0336)),
  GeorgianGeoEntry(name: 'წყალტუბო', region: 'იმერეთი', coordinates: LatLng(42.3267, 42.5997)),
  GeorgianGeoEntry(name: 'ბაღდათი', region: 'იმერეთი', coordinates: LatLng(42.0667, 42.8167)),
  GeorgianGeoEntry(name: 'ვანი', region: 'იმერეთი', coordinates: LatLng(42.0833, 42.5000)),
  GeorgianGeoEntry(name: 'ხონი', region: 'იმერეთი', coordinates: LatLng(42.3167, 42.4167)),
  GeorgianGeoEntry(name: 'თერჯოლა', region: 'იმერეთი', coordinates: LatLng(42.1833, 42.9833)),
  GeorgianGeoEntry(name: 'საჩხერე', region: 'იმერეთი', coordinates: LatLng(42.3400, 43.4150)),
  GeorgianGeoEntry(name: 'ჭიათურა', region: 'იმერეთი', coordinates: LatLng(42.2900, 43.2800)),
  GeorgianGeoEntry(name: 'ხარაგაული', region: 'იმერეთი', coordinates: LatLng(42.0167, 43.2000)),

  // შიდა ქართლი (Shida Kartli)
  GeorgianGeoEntry(name: 'გორი', region: 'შიდა ქართლი', coordinates: LatLng(41.9842, 44.1158)),
  GeorgianGeoEntry(name: 'კასპი', region: 'შიდა ქართლი', coordinates: LatLng(41.9250, 44.4250)),
  GeorgianGeoEntry(name: 'ხაშური', region: 'შიდა ქართლი', coordinates: LatLng(41.9967, 43.5986)),
  GeorgianGeoEntry(name: 'ქარელი', region: 'შიდა ქართლი', coordinates: LatLng(42.0231, 43.8944)),

  // ქვემო ქართლი (Kvemo Kartli)
  GeorgianGeoEntry(name: 'რუსთავი', region: 'ქვემო ქართლი', coordinates: LatLng(41.5495, 45.0186)),
  GeorgianGeoEntry(name: 'მარნეული', region: 'ქვემო ქართლი', coordinates: LatLng(41.4747, 44.8089)),
  GeorgianGeoEntry(name: 'ბოლნისი', region: 'ქვემო ქართლი', coordinates: LatLng(41.4489, 44.5381)),
  GeorgianGeoEntry(name: 'გარდაბანი', region: 'ქვემო ქართლი', coordinates: LatLng(41.4600, 45.0928)),
  GeorgianGeoEntry(name: 'დმანისი', region: 'ქვემო ქართლი', coordinates: LatLng(41.3300, 44.3400)),
  GeorgianGeoEntry(name: 'თეთრიწყარო', region: 'ქვემო ქართლი', coordinates: LatLng(41.5500, 44.4600)),
  GeorgianGeoEntry(name: 'წალკა', region: 'ქვემო ქართლი', coordinates: LatLng(41.6000, 44.0889)),

  // სამეგრელო-ზემო სვანეთი (Samegrelo)
  GeorgianGeoEntry(name: 'ზუგდიდი', region: 'სამეგრელო', coordinates: LatLng(42.5088, 41.8709)),
  GeorgianGeoEntry(name: 'ფოთი', region: 'სამეგრელო', coordinates: LatLng(42.1462, 41.6720)),
  GeorgianGeoEntry(name: 'სენაკი', region: 'სამეგრელო', coordinates: LatLng(42.2689, 42.0678)),
  GeorgianGeoEntry(name: 'აბაშა', region: 'სამეგრელო', coordinates: LatLng(42.2039, 42.2064)),
  GeorgianGeoEntry(name: 'მარტვილი', region: 'სამეგრელო', coordinates: LatLng(42.4142, 42.3789)),
  GeorgianGeoEntry(name: 'ხობი', region: 'სამეგრელო', coordinates: LatLng(42.3167, 41.9000)),
  GeorgianGeoEntry(name: 'ჩხოროწყუ', region: 'სამეგრელო', coordinates: LatLng(42.5200, 42.1300)),
  GeorgianGeoEntry(name: 'წალენჯიხა', region: 'სამეგრელო', coordinates: LatLng(42.6050, 42.0700)),
  GeorgianGeoEntry(name: 'მესტია', region: 'სვანეთი', coordinates: LatLng(43.0442, 42.7297)),

  // გურია (Guria)
  GeorgianGeoEntry(name: 'ოზურგეთი', region: 'გურია', coordinates: LatLng(41.9269, 42.0006)),
  GeorgianGeoEntry(name: 'ლანჩხუთი', region: 'გურია', coordinates: LatLng(42.0875, 42.0361)),
  GeorgianGeoEntry(name: 'ჩოხატაური', region: 'გურია', coordinates: LatLng(42.0189, 42.2394)),
  GeorgianGeoEntry(name: 'ურეკი', region: 'გურია', coordinates: LatLng(41.9900, 41.7700)),

  // მცხეთა-მთიანეთი (Mtskheta-Mtianeti)
  GeorgianGeoEntry(name: 'მცხეთა', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(41.8458, 44.7188)),
  GeorgianGeoEntry(name: 'დუშეთი', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.0833, 44.7000)),
  GeorgianGeoEntry(name: 'თიანეთი', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.1089, 44.9628)),
  GeorgianGeoEntry(name: 'ყაზბეგი', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.6567, 44.6433)),
  GeorgianGeoEntry(name: 'გუდაური', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.4778, 44.4756)),

  // სამცხე-ჯავახეთი (Samtskhe-Javakheti)
  GeorgianGeoEntry(name: 'ახალციხე', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.6389, 42.9861)),
  GeorgianGeoEntry(name: 'ბორჯომი', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.8389, 43.3792)),
  GeorgianGeoEntry(name: 'ბაკურიანი', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.7500, 43.5333)),
  GeorgianGeoEntry(name: 'ასპინძა', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.5700, 43.2500)),
  GeorgianGeoEntry(name: 'ახალქალაქი', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.4056, 43.4861)),
  GeorgianGeoEntry(name: 'ნინოწმინდა', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.2647, 43.5900)),

  // რაჭა-ლეჩხუმი
  GeorgianGeoEntry(name: 'ამბროლაური', region: 'რაჭა', coordinates: LatLng(42.5200, 43.1400)),
  GeorgianGeoEntry(name: 'ონი', region: 'რაჭა', coordinates: LatLng(42.5800, 43.4400)),
  GeorgianGeoEntry(name: 'ცაგერი', region: 'ლეჩხუმი', coordinates: LatLng(42.6500, 42.7700)),
  GeorgianGeoEntry(name: 'ლენტეხი', region: 'სვანეთი', coordinates: LatLng(42.7900, 42.7200)),

  // თბილისი (Tbilisi)
  GeorgianGeoEntry(name: 'თბილისი', region: 'დედაქალაქი', coordinates: LatLng(41.7151, 44.8271)),
  GeorgianGeoEntry(name: 'ვაკე-საბურთალო', region: 'თბილისი', coordinates: LatLng(41.7250, 44.7500)),
  GeorgianGeoEntry(name: 'გლდანი-ნაძალადევი', region: 'თბილისი', coordinates: LatLng(41.7800, 44.8100)),
  GeorgianGeoEntry(name: 'ისანი-სამგორი', region: 'თბილისი', coordinates: LatLng(41.6900, 44.8700)),
];

/// Smart spatial & online reverse geocoding engine for Georgia
abstract final class GeorgianGeoLookup {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'User-Agent': 'AgroKeraApp/1.0 (contact@agrokera.ge)'},
    ),
  );

  static final Map<String, String> _cache = {};

  /// Haversine spherical distance calculation in kilometers
  static double distanceInKm(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        math.cos((p2.latitude - p1.latitude) * p) / 2 +
        math.cos(p1.latitude * p) *
            math.cos(p2.latitude * p) *
            (1 - math.cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  /// Instant, 100% offline-reliable nearest place resolver
  static String resolveInstantAddress(LatLng point) {
    GeorgianGeoEntry? bestEntry;
    double minDistance = double.infinity;

    for (final entry in kGeorgianSettlements) {
      final d = distanceInKm(point, entry.coordinates);
      if (d < minDistance) {
        minDistance = d;
        bestEntry = entry;
      }
    }

    if (bestEntry == null) {
      return 'საქართველო';
    }

    if (bestEntry.region == 'დედაქალაქი' || bestEntry.region == bestEntry.name) {
      return bestEntry.name;
    }

    return '${bestEntry.name}, ${bestEntry.region}';
  }

  /// Online reverse geocoding via OpenStreetMap Nominatim with Georgian localization
  static Future<String?> fetchNominatimAddress(LatLng point) async {
    final cacheKey = '${point.latitude.toStringAsFixed(4)}_${point.longitude.toStringAsFixed(4)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': point.latitude,
          'lon': point.longitude,
          'zoom': 18,
          'addressdetails': 1,
          'accept-language': 'ka',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final address = response.data!['address'] as Map<String, dynamic>?;
        if (address != null) {
          final settlement = address['village'] ??
              address['hamlet'] ??
              address['town'] ??
              address['city'] ??
              address['suburb'] ??
              address['municipality'];

          final region = address['county'] ?? address['state'] ?? address['region'];

          if (settlement != null) {
            final formatted = region != null && region != settlement
                ? '$settlement, $region'
                : settlement.toString();
            _cache[cacheKey] = formatted;
            return formatted;
          }
        }
      }
    } catch (_) {
      // Offline fallback: handled by resolveInstantAddress
    }

    return null;
  }
}

/// 1:1 Vector Barn Pin Painter matching user's reference in AgroKera brand colors
class AgroKeraBarnPinPainter extends CustomPainter {
  final Color pinColor;
  final Color innerColor;

  const AgroKeraBarnPinPainter({
    this.pinColor = AppColors.primary,
    this.innerColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final cx = r;
    final cy = r;
    final tipX = r;
    final tipY = h;

    // 1. Soft Ground Contact Shadow (horizontal oval)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, tipY + 2.5),
        width: w * 0.44,
        height: 5.5,
      ),
      shadowPaint,
    );

    // 2. Exact Teardrop Geometry
    final d = tipY - cy;
    final sinA = (r / d).clamp(0.0, 1.0);
    final a = math.asin(sinA);

    final leftTangentX = cx - r * sinA;
    final leftTangentY = cy + r * math.cos(a);

    final pinPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(leftTangentX, leftTangentY)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi / 2 + a,
        2 * math.pi - 2 * a,
        false,
      )
      ..lineTo(tipX, tipY)
      ..close();

    // Fill pin body with AgroKera emerald green
    final pinPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinPaint);

    // Crisp white outer contour for high contrast over any map tiles
    final pinBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pinPath, pinBorderPaint);

    // 3. Inner White Circle
    final innerR = r * 0.74;
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), innerR, innerPaint);

    // 4. Iconic Barn Vector Icon inside White Circle
    final wb = innerR * 1.34;
    final hb = innerR * 1.30;

    final barnBottom = cy + hb * 0.44;
    final roofApexY = cy - hb * 0.44;
    final eaveY = cy - hb * 0.04;

    final wallLeft = cx - wb * 0.36;
    final wallRight = cx + wb * 0.36;
    final roofLeft = cx - wb * 0.48;
    final roofRight = cx + wb * 0.48;

    final barnPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;

    // A) Ground line
    final groundPaint = Paint()
      ..color = pinColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - wb * 0.50, barnBottom),
      Offset(cx + wb * 0.50, barnBottom),
      groundPaint,
    );

    // B) Outer Roof Stroke / Fascia (creates double-roof architectural silhouette)
    final outerRoofPath = Path()
      ..moveTo(roofLeft - 0.5, eaveY + 2.5)
      ..lineTo(cx, roofApexY)
      ..lineTo(roofRight + 0.5, eaveY + 2.5);
    final outerRoofPaint = Paint()
      ..color = pinColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(outerRoofPath, outerRoofPaint);

    // C) Main Barn Building Body (Gable + Walls)
    final barnBodyPath = Path()
      ..moveTo(wallLeft, barnBottom - 1.8)
      ..lineTo(wallLeft, eaveY + 0.5)
      ..lineTo(cx, roofApexY + 3.2)
      ..lineTo(wallRight, eaveY + 0.5)
      ..lineTo(wallRight, barnBottom - 1.8)
      ..close();
    canvas.drawPath(barnBodyPath, barnPaint);

    // D) Attic 4-Pane Square Window
    final winTop = cy - hb * 0.24;
    final paneSize = innerR * 0.12;
    final gap = innerR * 0.06;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(cx - paneSize - gap / 2, winTop, paneSize, paneSize), whitePaint);
    canvas.drawRect(Rect.fromLTWH(cx + gap / 2, winTop, paneSize, paneSize), whitePaint);
    canvas.drawRect(Rect.fromLTWH(cx - paneSize - gap / 2, winTop + paneSize + gap, paneSize, paneSize), whitePaint);
    canvas.drawRect(Rect.fromLTWH(cx + gap / 2, winTop + paneSize + gap, paneSize, paneSize), whitePaint);

    // E) Barn Door with "X" Crossbuck Brace
    final doorW = wb * 0.36;
    final doorTop = cy + hb * 0.04;
    final doorBottom = barnBottom - 1.8;
    final doorLeft = cx - doorW / 2;
    final doorRight = cx + doorW / 2;
    final doorRect = Rect.fromLTRB(doorLeft, doorTop, doorRight, doorBottom);

    // White door surface
    canvas.drawRect(doorRect, whitePaint);

    // Door frame
    final doorFramePaint = Paint()
      ..color = pinColor
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(doorRect, doorFramePaint);

    // "X" cross brace
    canvas.drawLine(Offset(doorLeft, doorTop), Offset(doorRight, doorBottom), doorFramePaint);
    canvas.drawLine(Offset(doorRight, doorTop), Offset(doorLeft, doorBottom), doorFramePaint);
  }

  @override
  bool shouldRepaint(covariant AgroKeraBarnPinPainter oldDelegate) {
    return oldDelegate.pinColor != pinColor || oldDelegate.innerColor != innerColor;
  }
}

/// Custom Farm Pin Widget with Dynamic Address Pill & 1:1 Vector Barn Pin
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
        // Dynamic Address Tooltip Bubble above Pin
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.navigation, size: 12, color: AppColors.primary),
              const SizedBox(width: 5),
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

        // 1:1 Vector Barn Pin
        CustomPaint(
          size: const Size(36, 48),
          painter: const AgroKeraBarnPinPainter(
            pinColor: AppColors.primary,
            innerColor: Colors.white,
          ),
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

  void _recenter() {
    HapticFeedback.lightImpact();
    final target = _pinnedLocation ?? _resolveDefaultCoordinates(widget.locationText);
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

        // 1:1 Vector Barn Pin Marker (rendered when user tapped/placed pin)
        if (_pinnedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _pinnedLocation!,
                width: 170,
                height: 84,
                alignment: Alignment.topCenter,
                child: CustomFarmPinWidget(
                  label: _currentAddress,
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

                        // Dynamic Address indicator chip on top
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                ],
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

              // Dynamic Status Chip (top left)
              Positioned(
                top: 8,
                left: 8,
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
