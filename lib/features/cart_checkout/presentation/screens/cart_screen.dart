import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'კალათი',
            style: AppTypography.h1.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.lock,
                    size: 42,
                    color: Color(0xFF4EA668),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ავტორიზაცია აუცილებელია',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'კალათის სანახავად და შეკვეთის გასაფორმებლად გთხოვთ გაიაროთ ავტორიზაცია.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => AuthRequiredBottomSheet.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4EA668),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'შესვლა / რეგისტრაცია',
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

    final cartItems = ref.watch(cartProvider);
    final isEmpty = cartItems.isEmpty;
    final subtotal = cartItems.subtotal;
    final totalWeight = cartItems.totalWeight;
    final isMinimumMet = cartItems.isMinimumMet;

    if (isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'ჩემი კალათი',
            style: AppTypography.h1.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Empty Cart Illustration from provided SVG
                  SvgPicture.asset(
                    AppAssets.emptyCart,
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'შენი კალათი ცარიელია!',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'გადახედე ფერმერის განცხადებებს და\nდაამატე სასურველი პროდუქტები კალათში',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button to fill cart (restore sample items)
                  OutlinedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).restoreSampleItems();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    ),
                    child: Text(
                      'კალათის შევსება',
                      style: AppTypography.button.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
          'კალათი',
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.textPrimary, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('კალათის გასუფთავება'),
                  content: const Text('ნამდვილად გსურთ კალათიდან ყველა პროდუქტის წაშლა?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('გაუქმება'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isDetailsExpanded = false);
                        ref.read(cartProvider.notifier).clearCart();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'გასუფთავება',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Scrollable List of Cart Items
          Positioned.fill(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                _isDetailsExpanded ? 380 : 110,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: cartItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFF3F4F6),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(LucideIcons.image, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Product details & Stepper
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Red Trash Icon
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ref.read(cartProvider.notifier).removeItem(item.id);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(
                                      LucideIcons.trash2,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // Package Text
                            if (item.packageText.isNotEmpty)
                              Text(
                                item.packageText,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 2),

                            // Farmer Name
                            Text(
                              item.farmerName,
                              style: AppTypography.caption.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Price Column (Left) and Stepper (Right)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Total Price & Unit Price cleanly arranged vertically
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.totalPrice.toStringAsFixed(2)} ₾',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${item.pricePerUnit.toStringAsFixed(2)} ₾/${item.unit}',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Stepper: [-] qty [+]
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(cartProvider.notifier).decrement(item.id);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          child: Icon(
                                            LucideIcons.minus,
                                            size: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          '${item.quantity}',
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(cartProvider.notifier).increment(item.id);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          child: Icon(
                                            LucideIcons.plus,
                                            size: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. Translucent Backdrop when expanded (tapping collapses it)
          if (_isDetailsExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _isDetailsExpanded = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),

          // 3. Expandable Bottom Container (Smooth in-place expansion)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: _isDetailsExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(24))
                    : BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isDetailsExpanded ? 0.12 : 0.06),
                    blurRadius: _isDetailsExpanded ? 16 : 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth In-Place Expanded Details Section
                      if (_isDetailsExpanded) ...[
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(top: 10, bottom: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Header: Title & Close Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'შეკვეთის დეტალები',
                                  style: AppTypography.h1.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textPrimary),
                                  onPressed: () {
                                    setState(() {
                                      _isDetailsExpanded = false;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cart item count label
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'კალათი(${cartItems.length})',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Horizontal Product Thumbnails
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: cartItems.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: const Color(0xFFF3F4F6),
                                      child: Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          LucideIcons.shoppingBag,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${item.totalPrice.toStringAsFixed(2)}₾',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.totalWeight.toStringAsFixed(1)}კგ',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(color: Color(0xFFF3F4F6), height: 16),
                        ),

                        // Total Weight Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ჯამური წონა:',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${totalWeight.toStringAsFixed(1)} კგ',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Products Value Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'პროდუქტების ღირებულება:',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${subtotal.toStringAsFixed(2)} ₾',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],

                      // Always-Visible Bottom Bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: _isDetailsExpanded
                              ? const Border(top: BorderSide(color: Color(0xFFF3F4F6)))
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Total price with animated rotating chevron
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _isDetailsExpanded = !_isDetailsExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${subtotal.toStringAsFixed(2)}₾',
                                      style: AppTypography.h1.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedRotation(
                                      turns: _isDetailsExpanded ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      child: const Icon(
                                        LucideIcons.chevronUp,
                                        size: 20,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Checkout CTA Button
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const CheckoutScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4EA668),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isMinimumMet ? 'გაგრძელება' : '30₾ მინ.გადასახადი',
                                    style: AppTypography.button.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
