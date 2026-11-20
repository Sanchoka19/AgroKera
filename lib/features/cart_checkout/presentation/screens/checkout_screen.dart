import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../../orders/presentation/screens/client_orders_screen.dart';
import '../../../orders/presentation/screens/order_chat_screen.dart';
import '../../domain/models/payment_method_model.dart';
import '../../domain/services/checkout_service.dart';
import '../providers/cart_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/checkout/checkout_address_card.dart';
import '../widgets/checkout/checkout_delivery_method_card.dart';
import '../widgets/checkout/checkout_delivery_slot_card.dart';
import '../widgets/checkout/checkout_order_summary_card.dart';
import '../widgets/checkout/delivery_address_bottom_sheet.dart';
import '../widgets/checkout/delivery_fee_explanation_sheet.dart';
import '../widgets/checkout/delivery_slot_bottom_sheet.dart';
import '../widgets/payment/order_placed_dialog.dart';
import '../widgets/payment/payment_method_card.dart';
import 'package:agrokera/core/widgets/address_required_bottom_sheet.dart';
import '../../../profile/presentation/providers/user_address_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late String _address;
  String? _deliverySlot;
  bool _isPickupSelected = false;

  @override
  void initState() {
    super.initState();
    final active = ref.read(userAddressProvider).activeAddress;
    _address = active.isNotEmpty ? active : 'თბილისი, საქართველო';
  }

  void _showAddressDialog() {
    DeliveryAddressBottomSheet.show(
      context: context,
      currentAddress: _address,
      onAddressSelected: (newAddress) {
        setState(() => _address = newAddress);
        ref.read(userAddressProvider.notifier).setActiveAddress(newAddress);
      },
    );
  }

  void _showDeliverySlotDialog() {
    final marketplace = ref.read(marketplaceProvider);
    final cartItems = ref.read(cartProvider);
    final farmer = CheckoutService.resolveFarmer(marketplace, cartItems);
    final schedules = CheckoutService.generateDeliverySchedules(farmer);
    final slots = CheckoutService.generateDeliverySlots(farmer);
    final activeSlot = _deliverySlot ?? slots.first;

    DeliverySlotBottomSheet.show(
      context: context,
      farmer: farmer,
      schedules: schedules,
      activeSlot: activeSlot,
      onSlotSelected: (slot) {
        setState(() => _deliverySlot = slot);
      },
    );
  }

  Future<void> _submitOrder(double total) async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      AppToast.info(context, 'თქვენი კალათა ცარიელია');
      return;
    }

    final addressState = ref.read(userAddressProvider);
    if (!addressState.hasAddress) {
      AddressRequiredBottomSheet.show(context);
      return;
    }

    final marketplace = ref.read(marketplaceProvider);
    final farmer = CheckoutService.resolveFarmer(marketplace, cartItems);
    final matchedZone =
        CheckoutService.findMatchedDeliveryZone(_address, farmer);
    final isCovered = matchedZone != null && farmer.isDeliveryEnabled;
    final isWeightExceeded = cartItems.isWeightLimitExceeded;
    final isPickup = isWeightExceeded || _isPickupSelected || !isCovered;
    final finalDeliveryAddress = _address;

    final baseDeliveryFee = isPickup ? 0.0 : matchedZone.value;
    final effectiveHeavyFee = isPickup ? 0.0 : cartItems.heavyFee;
    final totalDeliveryFee =
        isPickup ? 0.0 : (baseDeliveryFee + effectiveHeavyFee);
    const platformFee = 0.0;

    // Domain guard: Must be authenticated customer/farmer
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated || auth.role == UserRole.guest) {
      AuthRequiredBottomSheet.show(context);
      return;
    }

    // Domain guard: Farmer cannot order their own product or order from themselves
    final hasOwnItem = cartItems.any((it) => auth.isOwnerOfCartItem(it));
    final isOwnFarmer = auth.isOwner(
      farmerId: farmer.id,
      farmName: farmer.farmName,
      farmerName: farmer.farmerName,
    );
    if (auth.role == UserRole.farmer && (hasOwnItem || isOwnFarmer)) {
      AppToast.error(
        context,
        'საკუთარი მეურნეობიდან შეკვეთის გაფორმება შეუძლებელია',
      );
      return;
    }

    // Pre-order stock validation against real-time marketplace stock
    final validation = ref
        .read(cartProvider.notifier)
        .validateAndSyncStock(marketplace.products);

    switch (validation) {
      case CartValidationContainsOwnProduct(:final productTitle):
        AppToast.error(
          context,
          'პროდუქტი "$productTitle" თქვენი მეურნეობისაა. შეკვეთის გაფორმება შეუძლებელია.',
        );
        return;
      case CartValidationOutOfStock(:final productTitle):
        AppToast.error(
          context,
          'პროდუქტი "$productTitle" მარაგში აღარ არის',
        );
        return;
      case CartValidationExceedsStock(
          :final productTitle,
          :final availableStock,
          :final unit,
        ):
        AppToast.error(
          context,
          'პროდუქტზე "$productTitle" ხელმისაწვდომია მხოლოდ $availableStock $unit. კალათა დაკორექტირდა.',
        );
        return;
      case CartValidationValid():
        break;
    }

    final paymentState = ref.read(paymentProvider);
    final paymentMethod = paymentState.selectedMethod;

    final activeDeliverySlot =
        _deliverySlot ?? CheckoutService.generateDeliverySlots(farmer).first;

    final created = await ref
        .read(farmerOrdersProvider.notifier)
        .createOrderFromCart(
          cartItems: cartItems,
          deliveryAddress: finalDeliveryAddress,
          deliveryTimeWindow: activeDeliverySlot,
          paymentMethod: paymentMethod.name.toUpperCase(),
          hasVat: false,
          deliveryFee: totalDeliveryFee,
          heavyFee: 0.0,
          platformFee: platformFee,
          isPickup: isPickup,
        );

    if (!mounted) return;

    OrderPlacedDialog.show(
      context,
      orderId: created.id,
      totalAmount: total,
      paymentMethod: paymentMethod,
      escrowDetails: paymentState.escrowDetails,
      isPickup: isPickup,
      location: farmer.location,
      onDismiss: () {
        ref.read(cartProvider.notifier).clearCart();
        Navigator.of(context).pop(); // dismiss dialog
        Navigator.of(context).pop(); // pop checkout
        Navigator.of(context).pop(); // pop cart -> return to home
      },
      onViewOrders: () {
        ref.read(cartProvider.notifier).clearCart();
        Navigator.of(context).pop(); // dismiss dialog
        Navigator.of(context).pop(); // pop checkout
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ClientOrdersScreen(),
          ),
        );
      },
      onOpenChat: () {
        ref.read(cartProvider.notifier).clearCart();
        Navigator.of(context).pop(); // dismiss dialog
        Navigator.of(context).pop(); // pop checkout
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderChatScreen(order: created),
          ),
        );
      },
    );
  }

  String _buildCtaButtonText(PaymentMethodType method, double amount) {
    switch (method) {
      case PaymentMethodType.bankTransfer:
      case PaymentMethodType.cash:
        return 'მოთხოვნის გაგზავნა • ${amount.toStringAsFixed(0)} ₾';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final marketplace = ref.watch(marketplaceProvider);
    final paymentState = ref.watch(paymentProvider);
    final farmer = CheckoutService.resolveFarmer(marketplace, cartItems);
    final matchedZone =
        CheckoutService.findMatchedDeliveryZone(_address, farmer);
    final isCovered = matchedZone != null && farmer.isDeliveryEnabled;
    final isWeightExceeded = cartItems.isWeightLimitExceeded;
    final isPickup = isWeightExceeded || _isPickupSelected || !isCovered;

    final subtotal = cartItems.isNotEmpty ? cartItems.subtotal : 65.0;
    final totalWeight = cartItems.isNotEmpty ? cartItems.totalWeight : 3.8;
    final baseDeliveryFee = isPickup ? 0.0 : matchedZone.value;
    final effectiveHeavyFee = isPickup ? 0.0 : cartItems.heavyFee;
    final totalDeliveryFee =
        isPickup ? 0.0 : (baseDeliveryFee + effectiveHeavyFee);
    final grandTotal = subtotal + totalDeliveryFee;
    final activeSlot =
        _deliverySlot ?? CheckoutService.generateDeliverySlots(farmer).first;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'გადახდა',
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            CheckoutAddressCard(
              address: _address,
              isCovered: isCovered,
              matchedZone: matchedZone,
              farmer: farmer,
              onChangePressed: _showAddressDialog,
            ),
            const SizedBox(height: 12),
            CheckoutDeliveryMethodCard(
              isPickup: isPickup,
              isCovered: isCovered,
              isWeightExceeded: isWeightExceeded,
              isHeavyOrder: cartItems.isHeavyOrder,
              totalWeight: totalWeight,
              effectiveHeavyFee: effectiveHeavyFee,
              vehicleLabel: cartItems.vehicleLabel,
              matchedZone: matchedZone,
              farmer: farmer,
              onPickupChanged: (val) => setState(() => _isPickupSelected = val),
            ),
            const SizedBox(height: 12),
            CheckoutDeliverySlotCard(
              isPickup: isPickup,
              selectedSlot: activeSlot,
              onChangePressed: _showDeliverySlotDialog,
            ),
            const SizedBox(height: 12),
            PaymentMethodCard(grandTotal: grandTotal),
            const SizedBox(height: 12),
            CheckoutOrderSummaryCard(
              subtotal: subtotal,
              totalDeliveryFee: totalDeliveryFee,
              grandTotal: grandTotal,
              isPickup: isPickup,
              onDeliveryFeeInfoTap: () {
                DeliveryFeeExplanationSheet.show(
                  context: context,
                  totalWeight: totalWeight,
                  baseFee: baseDeliveryFee,
                  heavyFee: effectiveHeavyFee,
                  totalFee: totalDeliveryFee,
                  vehicleType: cartItems.vehicleType,
                  isPickup: isPickup,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _submitOrder(grandTotal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _buildCtaButtonText(paymentState.selectedMethod, grandTotal),
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'თანხა წინასწარ არ იჭრება • გადახდა ფერმერის დასტურის შემდეგ',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
