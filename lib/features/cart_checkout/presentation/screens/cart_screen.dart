import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../data/models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart/cart_bottom_bar.dart';
import '../widgets/cart/cart_expanding_details_panel.dart';
import '../widgets/cart/cart_item_tile.dart';
import '../widgets/cart/empty_cart_view.dart';
import '../widgets/cart/swipe_to_dismiss_hint.dart';

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

    if (cartItems.isEmpty) {
      return const EmptyCartView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // 1. BASE LAYER: Top App Bar + Cart Items List
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Custom App Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft,
                              color: AppColors.textPrimary, size: 28),
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
                          icon: const Icon(LucideIcons.trash2,
                              color: AppColors.textPrimary, size: 22),
                          onPressed: _showClearDialog,
                        ),
                      ],
                    ),
                  ),

                  // Single-Farmer Store Indicator
                  if (cartItems.isNotEmpty &&
                      cartItems.first.farmerName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final itemCard = CartItemTile(
                          item: item,
                          onRemove: () {
                            final removedItem = item;
                            final removedIndex = index;
                            ref
                                .read(cartProvider.notifier)
                                .removeItem(removedItem.id);
                            _showRemovedSnackBar(removedItem, removedIndex);
                          },
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
                              ? SwipeToDismissHint(
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

          // 2. FULL-SCREEN BLUR OVERLAY
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

          // 3. EXPANDING DETAILS CONTAINER
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
                    color: Colors.black
                        .withValues(alpha: _isDetailsExpanded ? 0.14 : 0.06),
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
                    CartExpandingDetailsPanel(
                      cartItems: cartItems,
                      expandAnimation: _expandAnimation,
                      onClose: _collapseDetails,
                    ),
                    CartBottomBar(
                      isExpanded: _isDetailsExpanded,
                      expandAnimation: _expandAnimation,
                      onToggle: _toggleDetails,
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
