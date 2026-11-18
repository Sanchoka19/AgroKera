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
  /// Extracts exact road, house number, neighborhood, and city/village.
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
          final road = address['road']?.toString().trim();
          final houseNumber = address['house_number']?.toString().trim();
          final neighbourhood = address['neighbourhood']?.toString().trim() ??
              address['suburb']?.toString().trim();
          final settlement = address['village']?.toString().trim() ??
              address['hamlet']?.toString().trim() ??
              address['town']?.toString().trim() ??
              address['city']?.toString().trim() ??
              address['municipality']?.toString().trim();
          final region = address['county']?.toString().trim() ??
              address['state']?.toString().trim() ??
              address['region']?.toString().trim();

          final parts = <String>[];

          // 1. Street and house number (e.g. "ჭავჭავაძის გამზირი 9ა")
          if (road != null && road.isNotEmpty) {
            if (houseNumber != null && houseNumber.isNotEmpty) {
              parts.add('$road $houseNumber');
            } else {
              parts.add(road);
            }
          }

          // 2. Settlement / City / Village (e.g. "თბილისი" or "გურჯაანი")
          if (settlement != null && settlement.isNotEmpty) {
            if (!parts.any((p) => p.contains(settlement))) {
              parts.add(settlement);
            }
          } else if (neighbourhood != null && neighbourhood.isNotEmpty) {
            if (!parts.any((p) => p.contains(neighbourhood))) {
              parts.add(neighbourhood);
            }
          } else if (region != null && region.isNotEmpty) {
            if (!parts.any((p) => p.contains(region))) {
              parts.add(region);
            }
          }

          if (parts.isNotEmpty) {
            final formatted = parts.join(', ');
            _cache[cacheKey] = formatted;
            return formatted;
          }
        }
      }
    } catch (_) {
      // Fallback handled by caller
    }

    return null;
  }

  /// High-accuracy reverse geocoder: attempts online exact street & house number lookup,
  /// falling back seamlessly to offline nearest settlement resolution.
  static Future<String> resolveDetailedAddress(LatLng point) async {
    try {
      final online = await fetchNominatimAddress(point);
      if (online != null && online.trim().isNotEmpty) {
        return online.trim();
      }
    } catch (_) {}

    return resolveInstantAddress(point);
  }
}

