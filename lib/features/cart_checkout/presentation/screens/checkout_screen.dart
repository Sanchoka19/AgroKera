import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import '../../../marketplace/data/models/farmer_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../orders/presentation/providers/farmer_orders_provider.dart';
import '../../../orders/presentation/screens/client_orders_screen.dart';
import '../../../orders/presentation/screens/order_chat_screen.dart';
import '../providers/cart_provider.dart';
import '../../domain/models/payment_method_model.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment/order_placed_dialog.dart';
import '../widgets/payment/payment_method_card.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _address = 'ჭავჭავაძე - თბილისი';
  String? _deliverySlot;
  bool _isPickupSelected = false;

  List<String> _generateDeliverySlots(FarmerModel farmer) {
    if (!farmer.isDeliveryEnabled) {
      return ['თვითგატანა მეურნეობიდან (${farmer.deliveryCity})'];
    }

    final rawDays = farmer.deliveryDays.isNotEmpty
        ? farmer.deliveryDays.map(FarmerModel.normalizeDay).toList()
        : ['შაბათი'];

    const geoWeekdayMap = {
      DateTime.monday: 'ორშაბათი',
      DateTime.tuesday: 'სამშაბათი',
      DateTime.wednesday: 'ოთხშაბათი',
      DateTime.thursday: 'ხუთშაბათი',
      DateTime.friday: 'პარასკევი',
      DateTime.saturday: 'შაბათი',
      DateTime.sunday: 'კვირა',
    };

    const monthNames = [
      '',
      'იანვარი',
      'თებერვალი',
      'მარტი',
      'აპრილი',
      'მაისი',
      'ივნისი',
      'ივლისი',
      'აგვისტო',
      'სექტემბერი',
      'ოქტომბერი',
      'ნოემბერი',
      'დეკემბერი',
    ];

    final now = DateTime.now();
    final matchingDates = <DateTime>[];

    for (int i = 1; i <= 14; i++) {
      final date = now.add(Duration(days: i));
      final weekdayName = geoWeekdayMap[date.weekday];
      if (rawDays.contains(weekdayName)) {
        matchingDates.add(date);
        if (matchingDates.length >= 2) break;
      }
    }

    if (matchingDates.isEmpty) {
      return [
        '${rawDays.first}, 10:00 - 13:00',
        '${rawDays.first}, 14:00 - 18:00',
      ];
    }

    final slots = <String>[];
    for (final d in matchingDates) {
      final weekdayName = geoWeekdayMap[d.weekday] ?? '';
      final monthName = monthNames[d.month];
      slots.add('$weekdayName, ${d.day} $monthName, 10:00-13:00');
      slots.add('$weekdayName, ${d.day} $monthName, 14:00-18:00');
    }

    return slots;
  }

  FarmerModel _resolveFarmer(
    MarketplaceState marketplace,
    List<dynamic> cartItems,
  ) {
    if (cartItems.isNotEmpty) {
      final firstItem = cartItems.first;
      for (final p in marketplace.products) {
        if (p.id == firstItem.id) {
          for (final f in marketplace.farmers) {
            if (f.id == p.farmerId || f.farmerName == firstItem.farmerName) {
              return f;
            }
          }
        }
      }
      for (final f in marketplace.farmers) {
        if (f.farmerName == firstItem.farmerName) {
          return f;
        }
      }
    }
    if (marketplace.farmers.isNotEmpty) {
      return marketplace.farmers.first;
    }
    return const FarmerModel(
      id: 'default_farmer',
      farmName: 'აგრო ფერმა',
      farmerName: 'ფერმერი',
      location: 'საქართველო',
      rating: 5.0,
      reviewCount: 0,
      totalRatings: 0,
      isVerified: true,
      isVatPayer: false,
      avatarUrl: '',
      coverUrl: '',
      about: '',
      phone: '',
    );
  }

  MapEntry<String, double>? _findMatchedDeliveryZone(
    String address,
    FarmerModel farmer,
  ) {
    if (!farmer.isDeliveryEnabled) return null;
    final lowerAddr = address.toLowerCase();

    for (final entry in farmer.regionalDeliveryFees.entries) {
      if (lowerAddr.contains(entry.key.toLowerCase())) {
        return entry;
      }
    }

    if (lowerAddr.contains(farmer.deliveryCity.toLowerCase())) {
      return MapEntry(farmer.deliveryCity, farmer.deliveryFee);
    }

    return null;
  }

  Widget _buildAddressQuickChip(
    String label,
    String fullAddress,
    TextEditingController controller,
    StateSetter setModalState,
  ) {
    final isSelected = controller.text.trim() == fullAddress;
    return InkWell(
      onTap: () {
        setModalState(() {
          controller.text = fullAddress;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  void _showAddressDialog() {
    final controller = TextEditingController(text: _address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.mapPin,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'მიტანის მისამართი',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // TextField with clear button & pin prefix
                TextField(
                  controller: controller,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'შეიყვანეთ მისამართი (ქალაქი, ქუჩა)...',
                    hintStyle: GoogleFonts.notoSansGeorgian(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setModalState(() => controller.clear());
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 14),

                // Quick City Selector Pills
                Text(
                  'სწრაფი არჩევა:',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAddressQuickChip(
                      'თბილისი',
                      'ჭავჭავაძე - თბილისი',
                      controller,
                      setModalState,
                    ),
                    _buildAddressQuickChip(
                      'რუსთავი',
                      'რუსთავი, შარტავას 4',
                      controller,
                      setModalState,
                    ),
                    _buildAddressQuickChip(
                      'მცხეთა',
                      'მცხეთა, არსუკიძის 1',
                      controller,
                      setModalState,
                    ),
                    _buildAddressQuickChip(
                      'ბათუმი',
                      'ბათუმი, რუსთაველის 10',
                      controller,
                      setModalState,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // GPS Locator Button
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      LocationPermission perm =
                          await Geolocator.checkPermission();
                      if (perm == LocationPermission.denied) {
                        perm = await Geolocator.requestPermission();
                        if (perm == LocationPermission.denied) {
                          if (!ctx.mounted) return;
                          AppToast.error(
                            ctx,
                            'მდებარეობაზე წვდომის ნებართვა უარყოფილია',
                          );
                          return;
                        }
                      }
                      final pos = await Geolocator.getCurrentPosition();
                      final resolved = GeorgianGeoLookup.resolveInstantAddress(
                        LatLng(pos.latitude, pos.longitude),
                      );
                      if (!ctx.mounted) return;
                      setModalState(() => controller.text = resolved);
                    } catch (_) {
                      if (!ctx.mounted) return;
                      AppToast.error(
                        ctx,
                        'GPS მდებარეობის დადგენა ვერ მოხერხდა',
                      );
                    }
                  },
                  icon: const Icon(
                    LucideIcons.locateFixed,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'ჩემი მდებარეობის დადგენა (GPS)',
                    style: GoogleFonts.notoSansGeorgian(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
                const SizedBox(height: 16),

                // Save CTA Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() => _address = controller.text.trim());
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'მისამართის შენახვა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeliverySlotDialog() {
    final marketplace = ref.read(marketplaceProvider);
    final cartItems = ref.read(cartProvider);
    final farmer = _resolveFarmer(marketplace, cartItems);
    final slots = _generateDeliverySlots(farmer);
    final activeSlot = _deliverySlot ?? slots.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'აირჩიეთ მიტანის დრო',
              style: AppTypography.h1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'ფერმერის მიწოდების დღეები: ${farmer.deliveryDays.isNotEmpty ? farmer.deliveryDays.join(", ") : "შაბათი"}',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...slots.map(
              (s) => ListTile(
                title: Text(
                  s,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: activeSlot == s
                    ? const Icon(LucideIcons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _deliverySlot = s);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog(double total) async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      AppToast.info(context, 'თქვენი კალათა ცარიელია');
      return;
    }

    final marketplace = ref.read(marketplaceProvider);
    final farmer = _resolveFarmer(marketplace, cartItems);
    final matchedZone = _findMatchedDeliveryZone(_address, farmer);
    final isCovered = matchedZone != null && farmer.isDeliveryEnabled;
    final isWeightExceeded = cartItems.isWeightLimitExceeded;
    final isPickup = isWeightExceeded || _isPickupSelected || !isCovered;
    final finalDeliveryAddress = isPickup
        ? 'თვითგატანა მეურნეობიდან: ${farmer.farmName} (${farmer.location})'
        : _address;

    final baseDeliveryFee = isPickup ? 0.0 : matchedZone.value;
    final effectiveHeavyFee = isPickup ? 0.0 : cartItems.heavyFee;
    final totalDeliveryFee = isPickup ? 0.0 : (baseDeliveryFee + effectiveHeavyFee);
    const platformFee = 0.0;

    // Domain guard: Farmer cannot order their own product or order from themselves
    final auth = ref.read(authStateProvider);
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
        _deliverySlot ?? _generateDeliverySlots(farmer).first;

    String orderNumber = '38195';
    final created = await ref
        .read(farmerOrdersProvider.notifier)
        .createOrderFromCart(
          cartItems: cartItems,
          deliveryAddress: finalDeliveryAddress,
          deliveryTimeWindow: activeDeliverySlot,
          paymentMethod: paymentMethod.name.toUpperCase(),
          hasVat: farmer.isVatPayer,
          deliveryFee: totalDeliveryFee,
          heavyFee: 0.0,
          platformFee: platformFee,
          isPickup: isPickup,
        );
    orderNumber = created.id;
    if (!mounted) return;

    OrderPlacedDialog.show(
      context,
      orderId: orderNumber,
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
        return 'მოთხოვნის გაგზავნა • ${amount.toStringAsFixed(0)} ₾';
      case PaymentMethodType.cash:
        return 'მოთხოვნის გაგზავნა • ${amount.toStringAsFixed(0)} ₾';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final marketplace = ref.watch(marketplaceProvider);
    final paymentState = ref.watch(paymentProvider);
    final farmer = _resolveFarmer(marketplace, cartItems);
    final matchedZone = _findMatchedDeliveryZone(_address, farmer);
    final isCovered = matchedZone != null && farmer.isDeliveryEnabled;
    final isWeightExceeded = cartItems.isWeightLimitExceeded;
    final isPickup = isWeightExceeded || _isPickupSelected || !isCovered;

    final subtotal = cartItems.isNotEmpty ? cartItems.subtotal : 65.0;
    final totalWeight = cartItems.isNotEmpty ? cartItems.totalWeight : 3.8;
    final baseDeliveryFee = isPickup ? 0.0 : matchedZone.value;
    final effectiveHeavyFee = isPickup ? 0.0 : cartItems.heavyFee;
    final totalDeliveryFee = isPickup ? 0.0 : (baseDeliveryFee + effectiveHeavyFee);
    final grandTotal = subtotal + totalDeliveryFee;

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
            // Card 1: Delivery Address
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'მიტანის მისამართი',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAddressDialog,
                        child: Text(
                          'შეცვლა',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _address,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Coverage status banner
                  if (isCovered) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.checkCircle2,
                            size: 16,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'მიტანა ხელმისაწვდომია: ${matchedZone.key} (${matchedZone.value.toInt()} ₾) • ${farmer.deliveryDays.join(", ")}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.alertTriangle,
                                size: 16,
                                color: Color(0xFFE65100),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'მიტანა შეუძლებელია ამ მისამართზე',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ფერმერი მიტანას ახორციელებს მხოლოდ შემდეგ ზონებში: ${farmer.regionalDeliveryFees.isNotEmpty ? farmer.regionalDeliveryFees.keys.join(", ") : farmer.deliveryCity} (${farmer.deliveryDays.join(", ")}).\nშეკვეთა გადართულია თვითგატანაზე (0 ₾ • ${farmer.location}).',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: const Color(0xFFBF360C),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card 1.5: Delivery Method Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'მიღების მეთოდი',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isWeightExceeded) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'წონა (${totalWeight.toStringAsFixed(1)} კგ) აჭარბებს საკურიერო მიტანის ლიმიტს (250 კგ). ხელმისაწვდომია მხოლოდ თვითგატანა მეურნეობიდან.',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (cartItems.isHeavyOrder) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.truck,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'მძიმე შეკვეთა (${totalWeight.toStringAsFixed(1)} კგ) • ტრანსპორტირება: ${cartItems.vehicleLabel} (+${effectiveHeavyFee.toInt()} ₾)',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Delivery option
                      Expanded(
                        child: GestureDetector(
                          onTap: isWeightExceeded
                              ? () {
                                  AppToast.warning(
                                    context,
                                    'წონა (${totalWeight.toStringAsFixed(1)} კგ) აჭარბებს საკურიერო მიტანის ლიმიტს (250 კგ). ხელმისაწვდომია მხოლოდ თვითგატანა.',
                                  );
                                }
                              : (isCovered
                                  ? () =>
                                      setState(() => _isPickupSelected = false)
                                  : () {
                                      AppToast.warning(
                                        context,
                                        'ფერმერი ამ მისამართზე მიტანას ვერ უზრუნველყოფს',
                                      );
                                    }),
                          child: Opacity(
                            opacity:
                                (!isWeightExceeded && isCovered) ? 1.0 : 0.45,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (!isPickup && isCovered)
                                    ? AppColors.primaryLight
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (!isPickup && isCovered)
                                      ? AppColors.primary
                                      : const Color(0xFFE5E7EB),
                                  width: (!isPickup && isCovered) ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(
                                        LucideIcons.truck,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      if (!isPickup && isCovered)
                                        const Icon(
                                          LucideIcons.checkCircle,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'მიტანა',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isWeightExceeded
                                        ? '>250 კგ (შეუძლებელია)'
                                        : (isCovered
                                            ? '${matchedZone.value.toInt()} ₾'
                                            : 'მიუწვდომელია'),
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isCovered
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Self-pickup option
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPickupSelected = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPickup
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isPickup
                                    ? AppColors.primary
                                    : const Color(0xFFE5E7EB),
                                width: isPickup ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(
                                      LucideIcons.store,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    if (isPickup)
                                      const Icon(
                                        LucideIcons.checkCircle,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'თვითგატანა',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '0 ₾ • უფასო',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isPickup) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'მეურნეობის ლოკაცია: ${farmer.farmName} — ${farmer.location}',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Delivery Day
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isPickup ? 'გატანის დღე და დრო' : 'მიტანის დღე',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showDeliverySlotDialog,
                        child: Text(
                          'შეცვლა',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _deliverySlot ?? _generateDeliverySlots(farmer).first,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card 3: Payment Method
            PaymentMethodCard(grandTotal: grandTotal),
            const SizedBox(height: 12),

            // Card 4: Order Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'შეკვეთის შეჯამება',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Products fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'პროდუქტების საფასური',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${subtotal.toStringAsFixed(0)} ₾',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Delivery fee with info icon (Clickable -> Bottom Modal Breakdown)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _showDeliveryFeeExplanation(
                              context: context,
                              totalWeight: totalWeight,
                              baseFee: baseDeliveryFee,
                              heavyFee: effectiveHeavyFee,
                              totalFee: totalDeliveryFee,
                              vehicleType: cartItems.vehicleType,
                              isPickup: isPickup,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'მიტანის საფასური',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                LucideIcons.info,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPickup
                            ? '0 ₾ (თვითგატანა)'
                            : '${totalDeliveryFee.toStringAsFixed(0)} ₾',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isPickup
                              ? const Color(0xFF2E7D32)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  const SizedBox(height: 16),

                  // Grand total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'სრული ღირებულება:',
                          style: AppTypography.h1.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${grandTotal.toStringAsFixed(0)} ₾',
                        style: AppTypography.h1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                  onPressed: () => _showSuccessDialog(grandTotal),
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

  void _showDeliveryFeeExplanation({
    required BuildContext context,
    required double totalWeight,
    required double baseFee,
    required double heavyFee,
    required double totalFee,
    required DeliveryVehicleType vehicleType,
    required bool isPickup,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F7EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.truck,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'მიტანის საფასურის გაანგარიშება',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'შეკვეთის საერთო წონა: ${totalWeight.toStringAsFixed(1)} კგ',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'მიტანის ჯამური საფასური:',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      isPickup ? '0 ₾ (თვითგატანა)' : '${totalFee.toStringAsFixed(0)} ₾',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isPickup ? const Color(0xFF2E7D32) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ტარიფები წონის მიხედვით:',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              _buildDeliveryTierItem(
                title: 'სტანდარტული მიტანა (0 - 20 კგ)',
                subtitle: 'სტანდარტული კურიერი • საბაზისო საფასური',
                feeText: '${baseFee.toStringAsFixed(0)} ₾',
                isActive: !isPickup && vehicleType == DeliveryVehicleType.standardCourier,
                icon: LucideIcons.bike,
              ),
              const SizedBox(height: 8),
              _buildDeliveryTierItem(
                title: 'მსუბუქი ავტომობილი (20.01 - 60 კგ)',
                subtitle: 'საბაზისო (${baseFee.toStringAsFixed(0)} ₾) + მძიმე ტვირთი (8 ₾)',
                feeText: '${(baseFee + 8.0).toStringAsFixed(0)} ₾',
                isActive: !isPickup && vehicleType == DeliveryVehicleType.passengerCar,
                icon: LucideIcons.car,
              ),
              const SizedBox(height: 8),
              _buildDeliveryTierItem(
                title: 'სატვირთო / მინივენი (60.01 - 250 კგ)',
                subtitle: 'საბაზისო (${baseFee.toStringAsFixed(0)} ₾) + სატვირთო (45 ₾)',
                feeText: '${(baseFee + 45.0).toStringAsFixed(0)} ₾',
                isActive: !isPickup && vehicleType == DeliveryVehicleType.cargoVan,
                icon: LucideIcons.truck,
              ),
              const SizedBox(height: 8),
              _buildDeliveryTierItem(
                title: 'თვითგატანა (250+ კგ ან არჩეული)',
                subtitle: '250 კგ-ზე მეტ წონაზე საკურიერო მიტანა არ ხორციელდება',
                feeText: '0 ₾',
                isActive: isPickup,
                icon: LucideIcons.store,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'გასაგებია',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryTierItem({
    required String title,
    required String subtitle,
    required String feeText,
    required bool isActive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F7EE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primary : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12.5,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? const Color(0xFF0F172A) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'მიმდინარე',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            feeText,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isActive ? AppColors.primary : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
