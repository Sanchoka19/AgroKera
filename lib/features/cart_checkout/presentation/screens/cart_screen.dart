import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../navigation/presentation/screens/main_nav_screen.dart';
import '../../data/models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  bool _isDetailsExpanded = false;
  static bool _hasSeenCartSwipeHint = false;

  void _showRemovedSnackBar(CartItemModel item, int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '„${item.title}“ წაიშალა კალათიდან',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'გაუქმება',
          textColor: const Color(0xFF34D399),
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(cartProvider.notifier).restoreItem(item, index);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    if (_isDetailsExpanded) {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _isDetailsExpanded = false);
      });
    } else {
      setState(() => _isDetailsExpanded = true);
      _animController.forward();
    }
  }

  void _collapseDetails() {
    if (_isDetailsExpanded) {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _isDetailsExpanded = false);
      });
    }
  }

  Future<void> _showClearDialog() async {
    final confirmed = await AppConfirmationBottomSheet.showClearCart(
      context: context,
    );

    if (confirmed && mounted) {
      _collapseDetails();
      ref.read(cartProvider.notifier).clearCart();
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  // Button to navigate to Main / Home screen
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainNavScreen(initialIndex: 0),
                        ),
                        (route) => false,
                      );
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
      body: Stack(
        children: [
          // ==========================================
          // 1. BASE LAYER: Top App Bar + Cart Items List
          // Everything is inside the base layer so the blur filter covers all of it!
          // ==========================================
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Custom App Bar (Gets blurred when details sheet expands)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            'კალათი',
                            textAlign: TextAlign.center,
                            style: AppTypography.h1.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: AppColors.textPrimary, size: 22),
                          onPressed: _showClearDialog,
                        ),
                      ],
                    ),
                  ),

                  // Single-Farmer Store Indicator
                  if (cartItems.isNotEmpty && cartItems.first.farmerName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.store,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'მეურნეობა: ${cartItems.first.farmerName}',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Cart Items List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final isOwn = ref
                            .watch(authStateProvider)
                            .isOwnerOfCartItem(item);
                        final itemCard = Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOwn
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFF3F4F6),
                              width: isOwn ? 1.5 : 1,
                            ),
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
                                            HapticFeedback.lightImpact();
                                            final removedItem = item;
                                            final removedIndex = index;
                                            ref.read(cartProvider.notifier).removeItem(removedItem.id);
                                            _showRemovedSnackBar(removedItem, removedIndex);
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
                                    if (isOwn) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFFFCA5A5),
                                          ),
                                        ),
                                        child: Text(
                                          'თქვენი პროდუქტი (ამოიღეთ გასაგრძელებლად)',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${item.totalPrice.toStringAsFixed(2)} ₾',
                                              style: AppTypography.bodyMedium.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: item.isBulkDiscountApplied
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            if (item.isBulkDiscountApplied)
                                              Text(
                                                '${item.effectiveUnitPrice.toStringAsFixed(2)} ₾/${item.unit} (-${item.bulkDiscountPercent}%)',
                                                style: AppTypography.caption.copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              )
                                            else
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
                                                  if (item.quantity <= item.minOrderQuantity) {
                                                    AppToast.info(
                                                      context,
                                                      'მინიმალური შეკვეთაა ${item.minOrderQuantity.toInt()} ${item.unit}',
                                                    );
                                                    return;
                                                  }
                                                  ref.read(cartProvider.notifier).decrement(item.id);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  child: Icon(
                                                    LucideIcons.minus,
                                                    size: 16,
                                                    color: item.quantity <= item.minOrderQuantity
                                                        ? AppColors.textSecondary.withValues(alpha: 0.35)
                                                        : AppColors.textPrimary,
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
                                                  if (item.quantity >= item.stockQuantity) {
                                                    AppToast.info(
                                                      context,
                                                      'მარაგში მხოლოდ ${item.stockQuantity.toInt()} ${item.unit}-ია',
                                                    );
                                                    return;
                                                  }
                                                  final success = ref
                                                      .read(cartProvider.notifier)
                                                      .increment(item.id);
                                                  if (!success) {
                                                    AppToast.info(
                                                      context,
                                                      'მარაგში მხოლოდ ${item.stockQuantity.toInt()} ${item.unit}-ია',
                                                    );
                                                  }
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  child: Icon(
                                                    LucideIcons.plus,
                                                    size: 16,
                                                    color: item.quantity >= item.stockQuantity
                                                        ? AppColors.textSecondary.withValues(alpha: 0.35)
                                                        : AppColors.textPrimary,
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

                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.trash2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'წაშლა',
                                  style: GoogleFonts.notoSansGeorgian(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            HapticFeedback.mediumImpact();
                            final removedItem = item;
                            final removedIndex = index;
                            ref
                                .read(cartProvider.notifier)
                                .removeItem(removedItem.id);
                            _showRemovedSnackBar(removedItem, removedIndex);
                          },
                          child: (index == 0 && !_hasSeenCartSwipeHint)
                              ? _SwipeToDismissHint(
                                  onHintCompleted: () {
                                    _hasSeenCartSwipeHint = true;
                                  },
                                  child: itemCard,
                                )
                              : itemCard,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. FULL-SCREEN BLUR OVERLAY (Smooth animated blur across entire screen)
          // ==========================================
          if (_isDetailsExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _collapseDetails,
                child: AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final progress = _expandAnimation.value;
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 7.0 * progress,
                        sigmaY: 7.0 * progress,
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.18 * progress),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ==========================================
          // 3. EXPANDING DETAILS CONTAINER WITH SMOOTH SLIDE-UP ANIMATION
          // ==========================================
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
                    color: Colors.black.withValues(alpha: _isDetailsExpanded ? 0.14 : 0.06),
                    blurRadius: _isDetailsExpanded ? 20 : 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Smooth Animated Size & Slide for Details
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              margin: const EdgeInsets.only(top: 10, bottom: 4),
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
                                    onPressed: _collapseDetails,
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
                                          '${item.quantity} ${item.unit}',
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

                          // Total Quantity Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'პროდუქტების რაოდენობა:',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${cartItems.fold(0, (sum, i) => sum + i.quantity)} ერთეული',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Vehicle Capacity / Weight Banner in expanded details
                          if (cartItems.isWeightLimitExceeded)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'წონა (${totalWeight.toStringAsFixed(1)} კგ) აჭარბებს საკურიერო მიტანის ლიმიტს (250 კგ). ჩექაუთზე ხელმისაწვდომი იქნება მხოლოდ თვითგატანა.',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (cartItems.isHeavyOrder)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cartItems.vehicleType == DeliveryVehicleType.cargoVan
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: cartItems.vehicleType == DeliveryVehicleType.cargoVan
                                        ? const Color(0xFFBFDBFE)
                                        : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      cartItems.vehicleType == DeliveryVehicleType.cargoVan
                                          ? LucideIcons.truck
                                          : LucideIcons.car,
                                      size: 16,
                                      color: cartItems.vehicleType == DeliveryVehicleType.cargoVan
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'საჭირო ტრანსპორტი: ${cartItems.vehicleLabel} (+${cartItems.heavyFee.toInt()} ₾)',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: cartItems.vehicleType == DeliveryVehicleType.cargoVan
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                      ),
                    ),

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
                            onTap: _toggleDetails,
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
                                  RotationTransition(
                                    turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
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
                                  requireAuth(
                                    context,
                                    ref: ref,
                                    onAuthenticated: () {
                                      if (!isMinimumMet) {
                                        AppToast.info(
                                          context,
                                          'მინიმალური შეკვეთის თანხაა 30 ₾',
                                        );
                                        return;
                                      }
                                      final auth = ref.read(authStateProvider);
                                      final ownItem = cartItems
                                          .where((it) => auth.isOwnerOfCartItem(it))
                                          .firstOrNull;
                                      if (auth.role == UserRole.farmer &&
                                          ownItem != null) {
                                        AppToast.error(
                                          context,
                                          'კალათაში გაქვთ თქვენი მეურნეობის პროდუქტი ("${ownItem.title}"). შეკვეთის გასაგრძელებლად წაშალეთ იგი.',
                                        );
                                        return;
                                      }

                                      final validation = ref
                                          .read(cartProvider.notifier)
                                          .validateAndSyncStock(
                                            ref.read(marketplaceProvider).products,
                                          );

                                      switch (validation) {
                                        case CartValidationContainsOwnProduct(
                                            :final productTitle
                                          ):
                                          AppToast.error(
                                            context,
                                            'პროდუქტი "$productTitle" თქვენი მეურნეობისაა. შეკვეთის გასაგრძელებლად წაშალეთ იგი.',
                                          );
                                          return;
                                        case CartValidationOutOfStock(
                                            :final productTitle
                                          ):
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
                                            'პროდუქტზე "$productTitle" მარაგში მხოლოდ $availableStock $unit-ია',
                                          );
                                          return;
                                        case CartValidationValid():
                                          break;
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CheckoutScreen(),
                                        ),
                                      );
                                    },
                                  );
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
        ],
      ),
    );
  }
}

/// Subtle "Peek" hint animation that slides the first item slightly left
/// to reveal the delete action, then bounces back, teaching the user the swipe gesture.
class _SwipeToDismissHint extends StatefulWidget {
  final Widget child;
  final VoidCallback? onHintCompleted;

  const _SwipeToDismissHint({
    required this.child,
    this.onHintCompleted,
  });

  @override
  State<_SwipeToDismissHint> createState() => _SwipeToDismissHintState();
}

class _SwipeToDismissHintState extends State<_SwipeToDismissHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.09, 0.0),
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.09, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_controller);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.onHintCompleted?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}
