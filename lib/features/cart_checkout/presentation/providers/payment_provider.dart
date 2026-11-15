import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_method_model.dart';

/// Manages active payment method selection, escrow configurations, and clipboard actions
class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() {
    return const PaymentState();
  }

  void selectMethod(PaymentMethodType method) {
    state = state.copyWith(selectedMethod: method);
  }

  void updateSavedCard(SavedCardDetails card) {
    state = state.copyWith(savedCard: card);
  }

  Future<void> copyIbanToClipboard() async {
    await Clipboard.setData(ClipboardData(text: state.escrowDetails.iban));
  }

  Future<void> copyTextToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

final paymentProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(PaymentNotifier.new);

