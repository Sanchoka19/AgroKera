import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/services/georgian_geo_lookup_service.dart';
import 'package:agrokera/features/profile/data/address_repository.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';

/// Business logic Notifier managing saved delivery & farm addresses.
class UserAddressNotifier extends Notifier<UserAddressState> {
  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  @override
  UserAddressState build() {
    unawaited(Future.microtask(_init));
    return const UserAddressState();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final addresses = await _repo.loadAddresses();
      final active = await _repo.loadActiveAddress();
      state = state.copyWith(
        addresses: addresses,
        activeAddress: active,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sets active address across the entire application (Checkout, Profile, Orders)
  Future<void> setActiveAddress(String newAddress) async {
    final clean = newAddress.trim();
    if (clean.isEmpty) return;

    state = state.copyWith(activeAddress: clean);
    await _repo.saveActiveAddress(clean);

    // Sync with AuthState and backend profile
    ref.read(authStateProvider.notifier).updateUserAddress(clean);
  }

  /// Adds a new address to the user's address book
  Future<void> addAddress(UserAddress newAddress) async {
    final shouldBeDefault = newAddress.isDefault || state.addresses.isEmpty;
    final addressToAdd = newAddress.copyWith(isDefault: shouldBeDefault);

    List<UserAddress> updatedList;
    if (shouldBeDefault) {
      updatedList = state.addresses
          .map((a) => a.copyWith(isDefault: false))
          .toList()
        ..add(addressToAdd);
    } else {
      updatedList = [...state.addresses, addressToAdd];
    }

    final newActive = shouldBeDefault
        ? addressToAdd.formattedAddress
        : state.activeAddress;

    state = state.copyWith(
      addresses: updatedList,
      activeAddress: newActive,
    );

    await _repo.saveAddresses(updatedList);
    if (shouldBeDefault) {
      await setActiveAddress(newActive);
    }
  }

  /// Updates an existing address
  Future<void> updateAddress(UserAddress updatedAddress) async {
    final updatedList = state.addresses.map((a) {
      if (a.id == updatedAddress.id) {
        return updatedAddress;
      }
      return updatedAddress.isDefault ? a.copyWith(isDefault: false) : a;
    }).toList();

    final newActive = updatedAddress.isDefault
        ? updatedAddress.formattedAddress
        : state.activeAddress;

    state = state.copyWith(
      addresses: updatedList,
      activeAddress: newActive,
    );

    await _repo.saveAddresses(updatedList);
    if (updatedAddress.isDefault) {
      await setActiveAddress(newActive);
    }
  }

  /// Deletes an address by its ID
  Future<void> deleteAddress(String addressId) async {
    final target = state.addresses.where((a) => a.id == addressId).firstOrNull;
    final remaining = state.addresses.where((a) => a.id != addressId).toList();

    String newActive = state.activeAddress;

    if (target != null && target.isDefault && remaining.isNotEmpty) {
      remaining[0] = remaining[0].copyWith(isDefault: true);
      newActive = remaining[0].formattedAddress;
    }

    state = state.copyWith(
      addresses: remaining,
      activeAddress: newActive,
    );

    await _repo.saveAddresses(remaining);
    if (target != null && target.isDefault && remaining.isNotEmpty) {
      await setActiveAddress(newActive);
    }
  }

  /// Sets an address as the default primary address
  Future<void> setDefaultAddress(String addressId) async {
    final updatedList = state.addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();

    final def = updatedList.firstWhere((a) => a.id == addressId);
    final newActive = def.formattedAddress;

    state = state.copyWith(
      addresses: updatedList,
      activeAddress: newActive,
    );

    await _repo.saveAddresses(updatedList);
    await setActiveAddress(newActive);
  }

  /// Detects GPS location and resolves to a Georgian address string
  Future<String?> detectGpsAddress() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition();
      return GeorgianGeoLookup.resolveInstantAddress(
        LatLng(pos.latitude, pos.longitude),
      );
    } catch (_) {
      return null;
    }
  }
}

final userAddressProvider =
    NotifierProvider<UserAddressNotifier, UserAddressState>(
  UserAddressNotifier.new,
);
