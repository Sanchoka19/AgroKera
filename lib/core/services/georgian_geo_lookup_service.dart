import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../constants/georgian_geo_data.dart';

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
    final cacheKey =
        '${point.latitude.toStringAsFixed(4)}_${point.longitude.toStringAsFixed(4)}';
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

          final region =
              address['county'] ?? address['state'] ?? address['region'];

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

