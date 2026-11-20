import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/constants/app_assets.dart';
import 'package:agrokera/core/storage/secure_storage_service.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import '../models/farmer_onboarding_state.dart';
import '../widgets/farmer_map_widget.dart';
import 'farmer_onboarding_validator.dart';

final farmerOnboardingProvider =
    NotifierProvider<FarmerOnboardingNotifier, FarmerOnboardingState>(
  FarmerOnboardingNotifier.new,
);

class FarmerOnboardingNotifier extends Notifier<FarmerOnboardingState> {
  Timer? _timer;

  @override
  FarmerOnboardingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const FarmerOnboardingState();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        timer.cancel();
      }
    });
  }

  void resetTimer([int seconds = 540]) {
    _timer?.cancel();
    state = state.copyWith(secondsRemaining: seconds);
    startTimer();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void setStep(int step) {
    if (step >= 1 && step <= 6) {
      state = state.copyWith(currentStep: step);
      if (step == 6) {
        startTimer();
      }
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setFarmName(String name) {
    state = state.copyWith(farmName: name);
  }

  void setFarmPhoto({required String path, required String name}) {
    state = state.copyWith(
      hasFarmPhoto: true,
      farmPhotoPath: path,
      farmPhotoName: name,
    );
  }

  void setRegion(String region) {
    final availableCities =
        FarmerOnboardingState.citiesByRegion[region] ?? ['თელავი'];
    final newCity = availableCities.contains(state.selectedCity)
        ? state.selectedCity
        : availableCities.first;
    state = state.copyWith(
      selectedRegion: region,
      selectedCity: newCity,
      dynamicAddress: '$region, $newCity',
    );
  }

  void setCity(String city) {
    state = state.copyWith(
      selectedCity: city,
      dynamicAddress: '${state.selectedRegion}, $city',
    );
  }

  void setLocation(LatLng point, {String? address}) {
    state = state.copyWith(
      selectedLocation: point,
      dynamicAddress: address ?? state.dynamicAddress,
    );
  }

  void setDynamicAddress(String address) {
    state = state.copyWith(dynamicAddress: address);
  }

  void setLandmark(String landmark) {
    state = state.copyWith(landmark: landmark);
  }

  Future<String> detectGpsLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('მდებარეობაზე წვდომის ნებართვა უარყოფილია');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('მდებარეობის ნებართვა დაბლოკილია პარამეტრებიდან');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final point = LatLng(pos.latitude, pos.longitude);
    final resolved = await GeorgianGeoLookup.resolveDetailedAddress(point);
    state = state.copyWith(
      selectedLocation: point,
      dynamicAddress: resolved,
    );
    return resolved;
  }

  void setStatus(LegalStatus status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setIdNumber(String id) {
    state = state.copyWith(idNumber: id);
  }

  void setSelfie(String fileName) {
    state = state.copyWith(
      uploadedSelfie: true,
      selfieFileName: fileName,
    );
  }

  void setIdFront(String fileName) {
    state = state.copyWith(
      uploadedIdFront: true,
      idFrontFileName: fileName,
    );
  }

  void setIdBack(String fileName) {
    state = state.copyWith(
      uploadedIdBack: true,
      idBackFileName: fileName,
    );
  }

  void setBank(String bank) {
    state = state.copyWith(selectedBank: bank);
  }

  void setIban(String iban) {
    state = state.copyWith(iban: iban);
  }

  void togglePickupEnabled() {
    // In AgroKera, self-pickup is a mandatory baseline condition and cannot be disabled
    state = state.copyWith(isPickupEnabled: true);
  }

  void toggleDeliveryEnabled() {
    state = state.copyWith(isDeliveryEnabled: !state.isDeliveryEnabled);
  }

  void setDeliveryCity(String city) {
    state = state.copyWith(deliveryCity: city);
  }

  void toggleDeliveryDay(String day) {
    final currentDays = List<String>.from(state.deliveryDays);
    if (currentDays.contains(day)) {
      currentDays.remove(day);
    } else {
      currentDays.add(day);
    }
    state = state.copyWith(deliveryDays: currentDays);
  }

  void setDeliveryFee(double fee) {
    state = state.copyWith(deliveryFee: fee, isFreeDelivery: false);
  }

  void toggleFreeDelivery(bool free) {
    state = state.copyWith(
      isFreeDelivery: free,
      deliveryFee: free ? 0.0 : 7.0,
    );
  }

  void setOrderCutoffHours(String hours) {
    state = state.copyWith(orderCutoffHours: hours);
  }

  void toggleAgreeTerms() {
    state = state.copyWith(agreeTerms: !state.agreeTerms);
  }

  void toggleAgreeQuality() {
    state = state.copyWith(agreeQuality: !state.agreeQuality);
  }

  void setOtpCode(String code) {
    state = state.copyWith(otpCode: code);
  }

  String? validateCurrentStep() {
    switch (state.currentStep) {
      case 1:
        return FarmerOnboardingValidator.validateStep1(
          farmName: state.farmName,
          hasFarmPhoto: state.hasFarmPhoto,
          region: state.selectedRegion,
          city: state.selectedCity,
        );
      case 2:
        return null;
      case 3:
        return FarmerOnboardingValidator.validateStep3(
          status: state.selectedStatus,
          idNumber: state.idNumber,
          uploadedSelfie: state.uploadedSelfie,
          uploadedIdFront: state.uploadedIdFront,
          uploadedIdBack: state.uploadedIdBack,
          bank: state.selectedBank,
          iban: state.iban,
        );
      case 4:
        return FarmerOnboardingValidator.validateStep4(
          isPickupEnabled: state.isPickupEnabled,
          isDeliveryEnabled: state.isDeliveryEnabled,
          deliveryDays: state.deliveryDays,
        );
      case 5:
        return FarmerOnboardingValidator.validateStep5(
          agreeTerms: state.agreeTerms,
          agreeQuality: state.agreeQuality,
        );
      case 6:
        return FarmerOnboardingValidator.validateStep6(
          otpCode: state.otpCode,
          requiredLength: 5,
        );
      default:
        return null;
    }
  }

  String resolveVerificationEmail() {
    if (state.customEmail != null &&
        state.customEmail!.trim().isNotEmpty) {
      return state.customEmail!.trim();
    }
    final userEmail = ref.read(authStateProvider).userEmail;
    if (userEmail != null &&
        userEmail.trim().isNotEmpty &&
        userEmail != 'example@gmail.com') {
      return userEmail.trim();
    }
    return 'ajariswyali123@gmail.com';
  }

  /// Updates email address in-place during onboarding and immediately resends OTP
  Future<bool> updateEmailAndResend(String newEmail) async {
    final cleanEmail = newEmail.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return false;
    }
    state = state.copyWith(
      customEmail: cleanEmail,
      otpCode: '',
    );
    ref.read(authStateProvider.notifier).updateEmail(cleanEmail);
    resetTimer(540);
    return sendOtp();
  }

  Future<bool> sendOtp() async {
    final email = resolveVerificationEmail();
    return ref.read(authStateProvider.notifier).sendEmailOtp(email);
  }

  Future<String?> verifyOtp(String code) async {
    final email = resolveVerificationEmail();
    return ref.read(authStateProvider.notifier).verifyEmailOtp(
          email: email,
          code: code,
        );
  }

  void completeOnboarding() {
    final effectiveCover = state.farmPhotoPath ?? AppAssets.defaultFarmCover;
    final effectiveAddress = state.dynamicAddress.trim().isNotEmpty
        ? state.dynamicAddress.trim()
        : '${state.selectedCity}, ${state.selectedRegion}';

    ref.read(authStateProvider.notifier).completeFarmerOnboarding(
      farmName: state.farmName,
      region: state.selectedRegion,
      city: state.selectedCity,
      address: effectiveAddress,
      coverUrl: effectiveCover,
    );

    // Persist farm location & optional landmark immediately to secure storage
    unawaited(ref.read(secureStorageProvider).saveFarmLocation(effectiveAddress));
    if (state.landmark.trim().isNotEmpty) {
      unawaited(
        ref.read(secureStorageProvider).saveFarmLandmark(state.landmark.trim()),
      );
    }

    // Sync location into live marketplace state for immediate profile consistency
    final currentFid = ref.read(authStateProvider).farmerId ?? 'farmer_1';
    ref.read(marketplaceProvider.notifier).updateFarmerLocation(
          farmerId: currentFid,
          location: effectiveAddress,
        );

    final cleanDays = state.deliveryDays
        .map(MarketplaceNotifier.normalizeDayName)
        .toSet()
        .toList();
    cleanDays.sort(
      (a, b) => MarketplaceNotifier.weekdayOrderIndex(a)
          .compareTo(MarketplaceNotifier.weekdayOrderIndex(b)),
    );

    unawaited(
      ref.read(marketplaceProvider.notifier).updateFarmerDeliverySettings(
            farmerId: currentFid,
            isDeliveryEnabled: state.isDeliveryEnabled,
            deliveryCity: state.selectedCity,
            deliveryDays: cleanDays.isNotEmpty ? cleanDays : const ['შაბათი'],
            deliveryFee: state.deliveryFee,
            regionalDeliveryFees: {state.selectedCity: state.deliveryFee},
            isPickupEnabled: true,
            location: effectiveAddress,
            updateAllDemoFarmers: currentFid == 'farmer_1' || currentFid == 'farmer_2',
          ),
    );

    unawaited(ref.read(marketplaceProvider.notifier).refreshFromBackend());
  }
}
