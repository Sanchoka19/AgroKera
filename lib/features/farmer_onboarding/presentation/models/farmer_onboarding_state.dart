import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LegalStatus {
  physical(
    'ფიზიკური პირი',
    'სასოფლო-სამეურნეო საქმიანობა პირადი ნომრით',
    LucideIcons.user,
  ),
  entrepreneur(
    'ინდ. მეწარმე',
    'რეგისტრირებული ინდივიდუალური მეწარმე',
    LucideIcons.briefcase,
  ),
  company(
    'შპს',
    'იურიდიული პირი და აგრო-კომპანია',
    LucideIcons.building2,
  );

  final String label;
  final String subtitle;
  final IconData icon;
  const LegalStatus(this.label, this.subtitle, this.icon);
}

@immutable
class FarmerOnboardingState {
  final int currentStep; // 1 to 6

  // Step 1: Farm Info & Address
  final String farmName;
  final bool hasFarmPhoto;
  final String? farmPhotoPath;
  final String? farmPhotoName;
  final String selectedRegion;
  final String selectedCity;
  final String dynamicAddress;
  final String landmark;
  final LatLng? selectedLocation;

  // Step 2: Legal Status
  final LegalStatus selectedStatus;

  // Step 3: Legal Details, Documents & Bank
  final String idNumber;
  final bool uploadedSelfie;
  final bool uploadedIdFront;
  final bool uploadedIdBack;
  final String? selfieFileName;
  final String? idFrontFileName;
  final String? idBackFileName;
  final String selectedBank;
  final String iban;

  // Step 4: Delivery & Fulfillment Options
  final bool isPickupEnabled;
  final String pickupHours;
  final bool isDeliveryEnabled;
  final String deliveryCity;
  final List<String> deliveryDays;
  final double deliveryFee;
  final bool isFreeDelivery;
  final String orderCutoffHours;

  // Step 5: Terms & Conditions (Review)
  final bool agreeTerms;
  final bool agreeQuality;

  // Step 6: SMS OTP Verification
  final String? customEmail;
  final int secondsRemaining;
  final String otpCode;
  final bool isSubmitting;
  final String? errorMessage;

  const FarmerOnboardingState({
    this.currentStep = 1,
    this.farmName = '',
    this.hasFarmPhoto = false,
    this.farmPhotoPath,
    this.farmPhotoName,
    this.selectedRegion = 'კახეთი',
    this.selectedCity = 'გურჯაანი',
    this.dynamicAddress = 'კახეთი, გურჯაანი',
    this.landmark = '',
    this.selectedLocation,
    this.selectedStatus = LegalStatus.physical,
    this.idNumber = '',
    this.uploadedSelfie = false,
    this.uploadedIdFront = false,
    this.uploadedIdBack = false,
    this.selfieFileName,
    this.idFrontFileName,
    this.idBackFileName,
    this.selectedBank = 'TBC',
    this.iban = '',
    this.isPickupEnabled = true,
    this.pickupHours = 'ყოველდღე 10:00 - 19:00',
    this.isDeliveryEnabled = false,
    this.deliveryCity = 'თბილისი',
    this.deliveryDays = const ['შაბ'],
    this.deliveryFee = 7.0,
    this.isFreeDelivery = false,
    this.orderCutoffHours = '24',
    this.agreeTerms = false,
    this.agreeQuality = false,
    this.customEmail,
    this.secondsRemaining = 540,
    this.otpCode = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  String get formattedTime {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes.$seconds';
  }

  static const List<String> weekDays = [
    'ორშ',
    'სამ',
    'ოთხ',
    'ხუთ',
    'პარ',
    'შაბ',
    'კვი',
  ];

  static const List<String> targetDeliveryCities = [
    'თბილისი',
    'რუსთავი',
    'ქუთაისი',
    'ბათუმი',
    'ადგილობრივი რეგიონი',
  ];

  static const List<String> regions = [
    'კახეთი',
    'იმერეთი',
    'შიდა ქართლი',
    'ქვემო ქართლი',
    'სამეგრელო',
    'გურია',
    'აჭარა',
    'მცხეთა-მთიანეთი',
  ];

  static const Map<String, List<String>> citiesByRegion = {
    'კახეთი': ['თელავი', 'გურჯაანი', 'ყვარელი', 'საგარეჯო', 'სიღნაღი', 'ახმეტა'],
    'იმერეთი': ['ქუთაისი', 'სამტრედია', 'ზესტაფონი', 'წყალტუბო'],
    'შიდა ქართლი': ['გორი', 'კასპი', 'ხაშური', 'ქარელი'],
    'ქვემო ქართლი': ['რუსთავი', 'მარნეული', 'ბოლნისი'],
    'სამეგრელო': ['ზუგდიდი', 'ფოთი', 'სენაკი'],
    'გურია': ['ოზურგეთი', 'ლანჩხუთი', 'ჩოხატაური'],
    'აჭარა': ['ბათუმი', 'ქობულეთი', 'ხელვაჩაური'],
    'მცხეთა-მთიანეთი': ['მცხეთა', 'დუშეთი', 'ყაზბეგი'],
  };

  static const List<String> banks = [
    'TBC',
    'BOG',
    'Liberty Bank',
    'BasisBank',
  ];

  static const List<Map<String, String>> presetFarmCovers = [
    {
      'title': 'ვენახი & მინდორი (კახეთი)',
      'url':
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1000&auto=format&fit=crop&q=80',
    },
    {
      'title': 'სათბური & ბოსტანი',
      'url':
          'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=1000&auto=format&fit=crop&q=80',
    },
    {
      'title': 'ხეხილის ბაღი',
      'url':
          'https://images.unsplash.com/photo-1618160702438-9b02ab6515c9?w=1000&auto=format&fit=crop&q=80',
    },
    {
      'title': 'საოჯახო მეურნეობა & მთები',
      'url':
          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
    },
  ];

  FarmerOnboardingState copyWith({
    int? currentStep,
    String? farmName,
    bool? hasFarmPhoto,
    String? farmPhotoPath,
    String? farmPhotoName,
    String? selectedRegion,
    String? selectedCity,
    String? dynamicAddress,
    String? landmark,
    LatLng? selectedLocation,
    LegalStatus? selectedStatus,
    String? idNumber,
    bool? uploadedSelfie,
    bool? uploadedIdFront,
    bool? uploadedIdBack,
    String? selfieFileName,
    String? idFrontFileName,
    String? idBackFileName,
    String? selectedBank,
    String? iban,
    bool? isPickupEnabled,
    String? pickupHours,
    bool? isDeliveryEnabled,
    String? deliveryCity,
    List<String>? deliveryDays,
    double? deliveryFee,
    bool? isFreeDelivery,
    String? orderCutoffHours,
    bool? agreeTerms,
    bool? agreeQuality,
    String? customEmail,
    int? secondsRemaining,
    String? otpCode,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return FarmerOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      farmName: farmName ?? this.farmName,
      hasFarmPhoto: hasFarmPhoto ?? this.hasFarmPhoto,
      farmPhotoPath: farmPhotoPath ?? this.farmPhotoPath,
      farmPhotoName: farmPhotoName ?? this.farmPhotoName,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedCity: selectedCity ?? this.selectedCity,
      dynamicAddress: dynamicAddress ?? this.dynamicAddress,
      landmark: landmark ?? this.landmark,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      idNumber: idNumber ?? this.idNumber,
      uploadedSelfie: uploadedSelfie ?? this.uploadedSelfie,
      uploadedIdFront: uploadedIdFront ?? this.uploadedIdFront,
      uploadedIdBack: uploadedIdBack ?? this.uploadedIdBack,
      selfieFileName: selfieFileName ?? this.selfieFileName,
      idFrontFileName: idFrontFileName ?? this.idFrontFileName,
      idBackFileName: idBackFileName ?? this.idBackFileName,
      selectedBank: selectedBank ?? this.selectedBank,
      iban: iban ?? this.iban,
      isPickupEnabled: isPickupEnabled ?? this.isPickupEnabled,
      pickupHours: pickupHours ?? this.pickupHours,
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isFreeDelivery: isFreeDelivery ?? this.isFreeDelivery,
      orderCutoffHours: orderCutoffHours ?? this.orderCutoffHours,
      agreeTerms: agreeTerms ?? this.agreeTerms,
      agreeQuality: agreeQuality ?? this.agreeQuality,
      customEmail: customEmail ?? this.customEmail,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      otpCode: otpCode ?? this.otpCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

