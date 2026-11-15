import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Supported Payment Methods in AgroKera
enum PaymentMethodType {
  bankTransfer, // საბანკო გადარიცხვა (AgroKera Escrow)
  cash, // ნაღდი ანგარიშსწორება (ადგილზე ჩაბარებისას)
  card; // საბანკო ბარათი (Visa / Mastercard)

  String get label {
    switch (this) {
      case PaymentMethodType.bankTransfer:
        return 'საბანკო გადარიცხვა';
      case PaymentMethodType.cash:
        return 'ნაღდი ფულით გადახდა';
      case PaymentMethodType.card:
        return 'საბანკო ბარათი';
    }
  }

  String get badgeText {
    switch (this) {
      case PaymentMethodType.bankTransfer:
        return 'Escrow დაცული';
      case PaymentMethodType.cash:
        return 'ადგილზე';
      case PaymentMethodType.card:
        return 'მყისიერი';
    }
  }

  String get shortSubtitle {
    switch (this) {
      case PaymentMethodType.bankTransfer:
        return 'AgroKera Escrow — თანხა გაიყინება ჩაბარებამდე';
      case PaymentMethodType.cash:
        return 'გადახდა პროდუქტის მიღებისას კურიერთან ან ფერმაში';
      case PaymentMethodType.card:
        return 'ონლაინ უსაფრთხო გადახდა Visa / Mastercard-ით';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodType.bankTransfer:
        return LucideIcons.building2;
      case PaymentMethodType.cash:
        return LucideIcons.banknote;
      case PaymentMethodType.card:
        return LucideIcons.creditCard;
    }
  }
}

/// AgroKera Escrow Bank Details for direct wire transfers.
/// Funds remain frozen in AgroKera escrow until customer confirms order delivery.
class AgroKeraEscrowDetails {
  final String bankName;
  final String iban;
  final String recipientName;
  final String identificationCode;

  const AgroKeraEscrowDetails({
    this.bankName = 'თიბისი ბანკი (TBC Bank)',
    this.iban = 'GE29TB7553608011000018',
    this.recipientName = 'შპს "აგროკერა" (AgroKera LLC)',
    this.identificationCode = '405123456',
  });

  static const AgroKeraEscrowDetails standard = AgroKeraEscrowDetails();
}

/// Saved credit/debit card representation
class SavedCardDetails {
  final String brand;
  final String lastFour;
  final String expiry;
  final String holderName;

  const SavedCardDetails({
    this.brand = 'Visa',
    this.lastFour = '4242',
    this.expiry = '12/28',
    this.holderName = 'SABA EVGENIDZE',
  });

  String get maskedNumber => '•••• •••• •••• $lastFour';
}

/// Immutable payment state
class PaymentState {
  final PaymentMethodType selectedMethod;
  final AgroKeraEscrowDetails escrowDetails;
  final SavedCardDetails? savedCard;

  const PaymentState({
    this.selectedMethod = PaymentMethodType.bankTransfer,
    this.escrowDetails = AgroKeraEscrowDetails.standard,
    this.savedCard = const SavedCardDetails(),
  });

  PaymentState copyWith({
    PaymentMethodType? selectedMethod,
    AgroKeraEscrowDetails? escrowDetails,
    SavedCardDetails? savedCard,
  }) {
    return PaymentState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      escrowDetails: escrowDetails ?? this.escrowDetails,
      savedCard: savedCard ?? this.savedCard,
    );
  }
}

