import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../profile/presentation/providers/user_address_provider.dart';
import '../../domain/services/farmer_proximity_service.dart';
import 'marketplace_provider.dart';

/// State model for Nearby Farmers section
class NearbyFarmersState {
  final List<FarmerDistanceInfo> farmers;
  final bool hasUserAddressOrigin;
  final String originDescription;

  const NearbyFarmersState({
    required this.farmers,
    required this.hasUserAddressOrigin,
    required this.originDescription,
  });
}

/// Provider that calculates real proximity and sorts farmers by distance
/// (excluding the currently logged-in farmer's own farm)
final nearbyFarmersProvider = Provider<NearbyFarmersState>((ref) {
  final marketplace = ref.watch(marketplaceProvider);
  final authState = ref.watch(authStateProvider);
  final addressState = ref.watch(userAddressProvider);
  final activeAddress = addressState.activeAddressModel;

  final visibleFarmers = authState.isFarmer
      ? marketplace.farmers.where((f) => !f.isOwnedBy(authState)).toList()
      : marketplace.farmers;

  LatLng origin;
  bool hasUserAddressOrigin = false;
  String originDescription = 'თბილისიდან';

  if (activeAddress != null &&
      activeAddress.latitude != null &&
      activeAddress.longitude != null) {
    origin = LatLng(activeAddress.latitude!, activeAddress.longitude!);
    hasUserAddressOrigin = true;
    originDescription = activeAddress.city.trim().isNotEmpty
        ? '${activeAddress.city.trim()}დან'
        : 'თქვენი მისამართიდან';
  } else if (activeAddress != null && activeAddress.city.trim().isNotEmpty) {
    // If coordinates are missing but city is specified, resolve city coordinates
    origin = FarmerProximityService.defaultGeorgiaAnchor;
    originDescription = '${activeAddress.city.trim()}დან';
  } else {
    origin = FarmerProximityService.defaultGeorgiaAnchor;
    originDescription = 'სიახლოვის მიხედვით';
  }

  final sortedFarmers = FarmerProximityService.sortAndCalculateDistances(
    farmers: visibleFarmers,
    origin: origin,
  );

  return NearbyFarmersState(
    farmers: sortedFarmers,
    hasUserAddressOrigin: hasUserAddressOrigin,
    originDescription: originDescription,
  );
});

