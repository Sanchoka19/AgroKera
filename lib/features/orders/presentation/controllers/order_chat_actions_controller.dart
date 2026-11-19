import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../profile/presentation/providers/user_address_provider.dart';
import '../../domain/models/farmer_order_model.dart';
import '../../domain/models/order_message_model.dart';
import '../providers/order_chat_provider.dart';

/// Business logic controller for Order Chat actions.
/// Separates all permissions, payloads, and communication logic from UI.
class OrderChatActionsController {
  final Ref _ref;

  OrderChatActionsController(this._ref);

  /// Helper to resolve sender information according to user role
  ({String id, String name, UserRole role}) _resolveSender(FarmerOrder order) {
    final auth = _ref.read(authStateProvider);
    final isOrderSeller = auth.role == UserRole.farmer &&
        (auth.farmerId == order.farmerId ||
            order.farmerId == null ||
            order.clientId != auth.userId);

    final senderId = isOrderSeller
        ? (auth.farmerId ?? auth.userId ?? 'farmer_unknown')
        : (auth.userId ?? 'customer_unknown');
    final senderName = isOrderSeller
        ? (auth.farmName ?? auth.userName ?? 'ფერმერი')
        : (auth.userName ?? order.customerName);
    final senderRole = isOrderSeller ? UserRole.farmer : UserRole.customer;

    return (id: senderId, name: senderName, role: senderRole);
  }

  /// Resolves the customer's genuine address to share in chat, never leaking the farm pickup location
  String? resolveCustomerAddressToShare(FarmerOrder order) {
    // 1. If order has a genuine customer delivery address (not self-pickup farm address)
    final orderAddr = order.deliveryAddress?.trim();
    if (orderAddr != null &&
        orderAddr.isNotEmpty &&
        !order.isPickup &&
        !orderAddr.startsWith('თვითგატანა') &&
        !orderAddr.contains('მეურნეობიდან')) {
      return orderAddr;
    }

    // 2. Active address selected in user profile / address book
    final activeUserAddress =
        _ref.read(userAddressProvider).activeAddress.trim();
    if (activeUserAddress.isNotEmpty &&
        !activeUserAddress.startsWith('თვითგატანა') &&
        !activeUserAddress.contains('მეურნეობიდან')) {
      return activeUserAddress;
    }

    // 3. User address from AuthState
    final authUserAddress = _ref.read(authStateProvider).userAddress?.trim();
    if (authUserAddress != null &&
        authUserAddress.isNotEmpty &&
        !authUserAddress.startsWith('თვითგატანა') &&
        !authUserAddress.contains('მეურნეობიდან')) {
      return authUserAddress;
    }

    // 4. Fallback to orderAddr only if it does not point to farm pickup
    if (orderAddr != null &&
        orderAddr.isNotEmpty &&
        !orderAddr.startsWith('თვითგატანა') &&
        !orderAddr.contains('მეურნეობიდან')) {
      return orderAddr;
    }

    return null;
  }

  /// Sends the formatted delivery address to the chat
  Future<bool> sendDeliveryAddress({
    required BuildContext context,
    required FarmerOrder order,
    String? overrideAddress,
  }) async {
    final resolvedAddress = overrideAddress?.trim().isNotEmpty == true
        ? overrideAddress!.trim()
        : resolveCustomerAddressToShare(order);

    if (resolvedAddress == null || resolvedAddress.isEmpty) {
      if (context.mounted) {
        AppToast.error(context, 'მიწოდების მისამართი ვერ მოიძებნა');
      }
      return false;
    }

    final sender = _resolveSender(order);
    final messageText = 'მიწოდების მისამართი:\n$resolvedAddress';

    try {
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.address,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'მისამართის გაგზავნა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Obtains current GPS location and shares Google Maps coordinates link
  Future<bool> sendCurrentGpsLocation({
    required BuildContext context,
    required FarmerOrder order,
  }) async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (context.mounted) {
        AppToast.error(context, 'გთხოვთ, ჩართოთ GPS ლოკაციის სერვისი ტელეფონში');
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          AppToast.error(context, 'ლოკაციის გაზიარებაზე ნებართვა უარყოფილია');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        AppToast.error(context, 'ლოკაციის ნებართვა დაბლოკილია პარამეტრებიდან');
      }
      return false;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
      final messageText = 'მიმდინარე GPS ლოკაცია:\n$mapsUrl';

      final sender = _resolveSender(order);
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.location,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'მიმდინარე ლოკაციის დადგენა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Sends building/intercom/gate code
  Future<bool> sendIntercomCode({
    required BuildContext context,
    required FarmerOrder order,
    required String codeDetails,
  }) async {
    final clean = codeDetails.trim();
    if (clean.isEmpty) return false;

    final sender = _resolveSender(order);
    final messageText = 'სადარბაზო / დომოფონი:\n$clean';

    try {
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.intercom,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'კოდის გაგზავნა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Securely sends the delivery PIN code to the chat
  Future<bool> sendDeliveryPin({
    required BuildContext context,
    required FarmerOrder order,
  }) async {
    final pin = order.deliveryPin.trim();
    if (pin.isEmpty) {
      if (context.mounted) {
        AppToast.error(context, 'ჩაბარების PIN კოდი ვერ მოიძებნა');
      }
      return false;
    }

    final sender = _resolveSender(order);
    final messageText = 'ჩაბარების PIN კოდი:\n$pin';

    try {
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.pin,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'PIN კოდის გაგზავნა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Shares order items summary
  Future<bool> sendOrderSummary({
    required BuildContext context,
    required FarmerOrder order,
  }) async {
    final itemsBuffer = StringBuffer();
    for (final item in order.items) {
      itemsBuffer.writeln('• ${item.name} (${item.quantityText})');
    }

    final messageText =
        'შეკვეთის შეჯამება (${order.trackingNumber ?? order.id}):\n'
        '${itemsBuffer.toString().trim()}\n'
        'სულ გადასახდელი: ₾${order.totalAmount.toStringAsFixed(2)}';

    final sender = _resolveSender(order);

    try {
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.summary,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'შეკვეთის ინფორმაციის გაგზავნა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Farmer asks customer for the delivery PIN code
  Future<bool> requestDeliveryPin({
    required BuildContext context,
    required FarmerOrder order,
  }) async {
    final sender = _resolveSender(order);
    const messageText =
        'გთხოვთ, შეამოწმოთ პროდუქცია და გადმომცეთ თქვენი 4-ნიშნა PIN კოდი შეკვეთის დასახურად.';

    try {
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.pinRequest,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'მოთხოვნის გაგზავნა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Farmer shares their bank account details / IBAN
  Future<bool> sendBankDetails({
    required BuildContext context,
    required FarmerOrder order,
    required String bankName,
    required String iban,
    String? beneficiaryName,
  }) async {
    final cleanIban = iban.trim().replaceAll(' ', '');
    if (cleanIban.isEmpty) {
      if (context.mounted) {
        AppToast.error(context, 'IBAN ანგარიშის ნომერი ცარიელია');
      }
      return false;
    }

    final auth = _ref.read(authStateProvider);
    final resolvedBeneficiary = beneficiaryName?.trim().isNotEmpty == true
        ? beneficiaryName!.trim()
        : (auth.farmName ?? auth.userName ?? 'აგროკერა ფერმერი');

    final messageText =
        'საბანკო რეკვიზიტები:\n'
        'ბანკი: ${bankName.trim()}\n'
        'მიმღები: $resolvedBeneficiary\n'
        'IBAN: $cleanIban';

    final sender = _resolveSender(order);

    try {
      await _ref.read(orderChatProvider.notifier).sendMessage(
            orderId: order.id,
            text: messageText,
            senderId: sender.id,
            senderRole: sender.role,
            senderName: sender.name,
            type: OrderMessageType.bankDetails,
          );
      return true;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'რეკვიზიტების გაგზავნა ვერ მოხერხდა');
      }
      return false;
    }
  }

  /// Copies phone number to clipboard with feedback
  void copyPhoneNumber(BuildContext context, String phone) {
    final clean = phone.trim();
    if (clean.isEmpty) {
      AppToast.error(context, 'ტელეფონის ნომერი მითითებული არ არის');
      return;
    }
    Clipboard.setData(ClipboardData(text: clean));
    AppToast.info(context, 'ტელეფონის ნომერი დაკოპირდა: $clean');
  }
}

final orderChatActionsControllerProvider =
    Provider<OrderChatActionsController>((ref) {
  return OrderChatActionsController(ref);
});
