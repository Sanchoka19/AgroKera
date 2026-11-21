import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';

class FarmerPayoutState {
  final String iban;
  final String bank;
  final String beneficiary;
  final bool isLoading;

  const FarmerPayoutState({
    this.iban = '',
    this.bank = '',
    this.beneficiary = '',
    this.isLoading = false,
  });

  bool get hasPayoutAccount =>
      iban.trim().replaceAll(' ', '').length >= 15 && bank.trim().isNotEmpty;

  FarmerPayoutState copyWith({
    String? iban,
    String? bank,
    String? beneficiary,
    bool? isLoading,
  }) {
    return FarmerPayoutState(
      iban: iban ?? this.iban,
      bank: bank ?? this.bank,
      beneficiary: beneficiary ?? this.beneficiary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FarmerPayoutNotifier extends Notifier<FarmerPayoutState> {
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  @override
  FarmerPayoutState build() {
    unawaited(Future.microtask(loadPayoutDetails));
    return const FarmerPayoutState();
  }

  Future<void> loadPayoutDetails() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: true);
    final userId = ref.read(authStateProvider).userId;
    final saved = await _storage.readFarmerPayoutDetails(userId: userId);

    if (!ref.mounted) return;
    state = state.copyWith(
      iban: saved.iban ?? '',
      bank: saved.bank ?? '',
      beneficiary: saved.beneficiary ?? '',
      isLoading: false,
    );
  }

  Future<void> savePayoutDetails({
    required String bank,
    required String iban,
    String? beneficiary,
  }) async {
    final cleanIban = iban.trim().replaceAll(' ', '');
    final userId = ref.read(authStateProvider).userId;

    await _storage.saveFarmerPayoutDetails(
      iban: cleanIban,
      bank: bank.trim(),
      beneficiary: beneficiary?.trim(),
      userId: userId,
    );

    if (!ref.mounted) return;
    state = state.copyWith(
      iban: cleanIban,
      bank: bank.trim(),
      beneficiary: beneficiary?.trim() ?? '',
    );
  }
}

final farmerPayoutProvider =
    NotifierProvider<FarmerPayoutNotifier, FarmerPayoutState>(
  FarmerPayoutNotifier.new,
);
