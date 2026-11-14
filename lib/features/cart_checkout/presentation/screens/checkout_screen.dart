import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../farmer_onboarding/presentation/widgets/farmer_map_widget.dart';
import '../../../orders/presentation/providers/farmer_orders_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/fee_breakdown_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _address = 'ჭავჭავაძე - თბილისი';
  String _deliverySlot = '28 ნოემბერი, 10:00-12:00';
  final String _paymentMethod = 'მთავრდება **** 4242';
  bool _hasCustomCard = true;

  void _showAddressDialog() {
    final controller = TextEditingController(text: _address);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('მიტანის მისამართი'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'შეიყვანეთ მისამართი',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  LocationPermission perm = await Geolocator.checkPermission();
                  if (perm == LocationPermission.denied) {
                    perm = await Geolocator.requestPermission();
                    if (perm == LocationPermission.denied) {
                      if (!mounted) return;
                      AppToast.error(
                        context,
                        'მდებარეობაზე წვდომის ნებართვა უარყოფილია',
                      );
                      return;
                    }
                  }
                  final pos = await Geolocator.getCurrentPosition();
                  final resolved = GeorgianGeoLookup.resolveInstantAddress(
                    LatLng(pos.latitude, pos.longitude),
                  );
                  controller.text = resolved;
                  setState(() => _address = resolved);
                } catch (_) {
                  if (!mounted) return;
                  AppToast.error(
                    context,
                    'GPS მდებარეობის დადგენა ვერ მოხერხდა',
                  );
                }
              },
              icon: const Icon(LucideIcons.locateFixed, size: 16),
              label: const Text('ჩემი მდებარეობის დადგენა (GPS)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('გაუქმება'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _address = controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('შენახვა', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeliverySlotDialog() {
    final slots = [
      '28 ნოემბერი, 10:00-12:00',
      '28 ნოემბერი, 14:00-16:00',
      '28 ნოემბერი, 18:00-20:00',
      '29 ნოემბერი, 10:00-12:00',
    ];
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
            const SizedBox(height: 12),
            ...slots.map(
              (s) => ListTile(
                title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: _deliverySlot == s
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

  void _showSuccessDialog(double total) {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isNotEmpty) {
      ref.read(farmerOrdersProvider.notifier).createOrderFromCart(
            cartItems: cartItems,
            deliveryAddress: _address,
            deliveryTimeWindow: _deliverySlot,
          );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCheck,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'შეკვეთა მიღებულია!',
                style: AppTypography.h1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'თქვენი შეკვეთა #38195 გადაეცა ფერმერს მოსამზადებლად. სრული ღირებულება: ${total.toStringAsFixed(0)} ₾',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).clearCart();
                    Navigator.of(ctx).pop(); // dialog
                    Navigator.of(context).pop(); // checkout
                    Navigator.of(context).pop(); // cart -> returns to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'მთავარზე დაბრუნება',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = cartItems.isNotEmpty ? cartItems.subtotal : 65.0;
    final totalWeight = cartItems.isNotEmpty ? cartItems.totalWeight : 3.8;
    final deliveryFee = cartItems.isNotEmpty ? cartItems.deliveryFee : 15.0;
    final platformFee = cartItems.isNotEmpty ? cartItems.platformFee : 10.0;
    final grandTotal = cartItems.isNotEmpty ? cartItems.grandTotal : 75.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
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
            // Top Free Delivery Promotional Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.gift,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'დაამატე 75 ლარის პროდუქცია და\nმიიღე უფასო მიტანა',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'დაამატე პროდუქტი',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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
                      Text(
                        'მიტანის მისამართი',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                      Text(
                        'მიტანის დღე',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                    _deliverySlot,
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
              child: Row(
                children: [
                  // Payment Card graphic badge
                  Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 6,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 6,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 6,
                          child: Container(
                            width: 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'გადახდის მეთოდი',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasCustomCard ? _paymentMethod : 'მთავრდება ****',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasCustomCard = !_hasCustomCard;
                      });
                    },
                    child: Text(
                      'დამატება',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      Text(
                        'პროდუქტების საფასური',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          color: AppColors.textSecondary,
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

                  // Delivery fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'მიტანის საფასური',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${deliveryFee.toStringAsFixed(0)} ₾',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Platform fee with info icon (Clickable -> FeeBreakdownSheet)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          FeeBreakdownSheet.show(
                            context,
                            currentWeight: totalWeight,
                            currentSubtotal: subtotal,
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'მოსაკრებელი',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 15,
                                color: AppColors.textSecondary,
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
                      Text(
                        '${platformFee.toStringAsFixed(0)} ₾',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                      Text(
                        'სრული ღირებულება:',
                        style: AppTypography.h1.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
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
            const SizedBox(height: 24),

            // Pay CTA Button
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
                  'გადახდა ${grandTotal.toStringAsFixed(0)}₾',
                  style: AppTypography.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
