import 'package:latlong2/latlong.dart';
import '../../../../core/constants/georgian_geo_data.dart';
import '../../../../core/services/georgian_geo_lookup_service.dart';
import '../../data/models/farmer_model.dart';

/// Immutable value object containing a farmer and their relative distance from origin
class FarmerDistanceInfo {
  final FarmerModel farmer;
  final double distanceKm;
  final String formattedDistance;

  const FarmerDistanceInfo({
    required this.farmer,
    required this.distanceKm,
    required this.formattedDistance,
  });

  /// Factory constructor formatting distance cleanly in Georgian units
  factory FarmerDistanceInfo.fromDistance({
    required FarmerModel farmer,
    required double distanceKm,
  }) {
    final String formatted;
    if (distanceKm < 1.0) {
      formatted = '${(distanceKm * 1000).round()} მ';
    } else if (distanceKm < 10.0) {
      formatted = '${distanceKm.toStringAsFixed(1)} კმ';
    } else {
      formatted = '${distanceKm.round()} კმ';
    }

    return FarmerDistanceInfo(
      farmer: farmer,
      distanceKm: distanceKm,
      formattedDistance: formatted,
    );
  }
}

/// Service dedicated to spatial distance and proximity sorting for farmers
/// Pure business and domain math logic, decoupled from UI widgets.
class FarmerProximityService {
  /// Default reference origin for Georgia (Tbilisi Freedom Square anchor)
  static const LatLng defaultGeorgiaAnchor = LatLng(41.7151, 44.8271);

  /// Resolves the geographic coordinates for a given farmer
  static LatLng getCoordinatesForFarmer(FarmerModel farmer) {
    // 1. Direct coordinates if available on model (future-proof)
    // 2. Resolve from location string matching Georgian settlements database
    final locationLower = farmer.location.toLowerCase();
    for (final settlement in kGeorgianSettlements) {
      if (locationLower.contains(settlement.name.toLowerCase())) {
        return settlement.coordinates;
      }
    }

    // 3. Check region match
    for (final settlement in kGeorgianSettlements) {
      if (locationLower.contains(settlement.region.toLowerCase())) {
        return settlement.coordinates;
      }
    }

    return defaultGeorgiaAnchor;
  }

  /// Calculates distances and returns farmers sorted in ascending proximity order
  static List<FarmerDistanceInfo> sortAndCalculateDistances({
    required List<FarmerModel> farmers,
    required LatLng origin,
  }) {
    final List<FarmerDistanceInfo> results = [];

    for (final farmer in farmers) {
      final farmerCoords = getCoordinatesForFarmer(farmer);
      final double distance = GeorgianGeoLookup.distanceInKm(origin, farmerCoords);
      results.add(
        FarmerDistanceInfo.fromDistance(
          farmer: farmer,
          distanceKm: distance,
        ),
      );
    }

    // Sort ascending by distance (closest first)
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }
}

