import '../models/farmer_onboarding_state.dart';

/// Pure validation logic for the 5-step Farmer Onboarding & Verification flow.
class FarmerOnboardingValidator {
  const FarmerOnboardingValidator._();

  /// Validates Step 1: Farm Info & Address
  static String? validateStep1({
    required String farmName,
    required bool hasFarmPhoto,
    required String region,
    required String city,
  }) {
    if (farmName.trim().isEmpty) {
      return 'გთხოვთ შეიყვანოთ ფერმის/მეურნეობის დასახელება';
    }
    if (region.trim().isEmpty || city.trim().isEmpty) {
      return 'გთხოვთ აირჩიოთ რეგიონი და ქალაქი/რაიონი';
    }
    return null;
  }

  /// Validates Step 3: Legal Details, KYC Documents & Bank IBAN
  static String? validateStep3({
    required LegalStatus status,
    required String idNumber,
    required bool uploadedSelfie,
    required bool uploadedIdFront,
    required bool uploadedIdBack,
    required String bank,
    required String iban,
  }) {
    final trimmedId = idNumber.trim();
    if (trimmedId.isEmpty) {
      return status == LegalStatus.physical
          ? 'გთხოვთ შეიყვანოთ პირადი ნომერი'
          : 'გთხოვთ შეიყვანოთ საიდენტიფიკაციო ნომერი';
    }
    if (status == LegalStatus.physical && trimmedId.length != 11) {
      return 'პირადი ნომერი უნდა შედგებოდეს 11 ციფრისგან';
    }
    if (status != LegalStatus.physical && trimmedId.length < 9) {
      return 'საიდენტიფიკაციო ნომერი უნდა შედგებოდეს მინიმუმ 9 ციფრისგან';
    }
    if (!uploadedSelfie) {
      return 'გთხოვთ ატვირთოთ სელფი პირადობის მოწმობით';
    }
    if (!uploadedIdFront) {
      return 'გთხოვთ ატვირთოთ პირადობის მოწმობის წინა მხარე';
    }
    if (!uploadedIdBack) {
      return 'გთხოვთ ატვირთოთ პირადობის მოწმობის უკანა მხარე';
    }
    if (bank.trim().isEmpty) {
      return 'გთხოვთ აირჩიოთ ბენეფიციარი ბანკი';
    }
    final trimmedIban = iban.trim().replaceAll(' ', '');
    if (trimmedIban.isEmpty) {
      return 'გთხოვთ შეიყვანოთ საბანკო ანგარიშის ნომერი (IBAN)';
    }
    if (trimmedIban.length < 10) {
      return 'გთხოვთ შეიყვანოთ სწორი IBAN ნომერი (მაგ: GE00TB0000000000000000)';
    }
    return null;
  }

  /// Validates Step 4: Delivery & Fulfillment Options
  static String? validateStep4({
    required bool isPickupEnabled,
    required bool isDeliveryEnabled,
    required List<String> deliveryDays,
  }) {
    if (!isPickupEnabled && !isDeliveryEnabled) {
      return 'გთხოვთ ჩართოთ მიწოდების მინიმუმ ერთი მეთოდი (თვითგატანა ან მიტანა)';
    }
    if (isDeliveryEnabled && deliveryDays.isEmpty) {
      return 'გთხოვთ მონიშნოთ მიტანის მინიმუმ 1 დღე';
    }
    return null;
  }

  /// Validates Step 5: Review & Terms Agreement
  static String? validateStep5({
    required bool agreeTerms,
    required bool agreeQuality,
  }) {
    if (!agreeTerms) {
      return 'გთხოვთ დაეთანხმოთ მომსახურების პირობებსა და კონფიდენციალურობის პოლიტიკას';
    }
    if (!agreeQuality) {
      return 'გთხოვთ დაადასტუროთ პასუხისმგებლობა პროდუქციის ხარისხსა და უსაფრთხოებაზე';
    }
    return null;
  }

  /// Validates Step 6: 5-digit SMS OTP Code
  static String? validateStep6({
    required String otpCode,
    required int requiredLength,
  }) {
    if (otpCode.trim().length < requiredLength) {
      return 'გთხოვთ სრულად შეიყვანოთ $requiredLength-ნიშნა SMS კოდი';
    }
    return null;
  }
}

