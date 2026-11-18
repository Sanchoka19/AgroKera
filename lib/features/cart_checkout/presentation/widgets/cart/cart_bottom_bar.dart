import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/address_required_bottom_sheet.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/core/widgets/auth_required_bottom_sheet.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import '../../providers/cart_provider.dart';
import '../../screens/checkout_screen.dart';

/// Bottom bar for cart screen displaying subtotal, expand chevron, and checkout CTA.
class CartBottomBar extends ConsumerWidget {
  final bool isExpanded;
  final Animation<double> expandAnimation;
  final VoidCallback onToggle;

  const CartBottomBar({
    super.key,
    required this.isExpanded,
    required this.expandAnimation,
    required this.onToggle,
  });

  void _onCheckoutPressed(BuildContext context, WidgetRef ref) {
    final cartItems = ref.read(cartProvider);
    final isMinimumMet = cartItems.isMinimumMet;

    requireAuth(
      context,
      ref: ref,
      onAuthenticated: () {
        if (!isMinimumMet) {
          AppToast.info(context, 'მინიმალური შეკვეთის თანხაა 30 ₾');
          return;
        }
        final auth = ref.read(authStateProvider);
        final ownItem = cartItems
            .where((it) => auth.isOwnerOfCartItem(it))
            .firstOrNull;
        if (auth.role == UserRole.farmer && ownItem != null) {
          AppToast.error(
            context,
            'კალათაში გაქვთ თქვენი მეურნეობის პროდუქტი ("${ownItem.title}"). შეკვეთის გასაგრძელებლად წაშალეთ იგი.',
          );
          return;
        }

        final validation = ref
            .read(cartProvider.notifier)
            .validateAndSyncStock(ref.read(marketplaceProvider).products);

        switch (validation) {
          case CartValidationContainsOwnProduct(:final productTitle):
            AppToast.error(
              context,
              'პროდუქტი "$productTitle" თქვენი მეურნეობისაა. შეკვეთის გასაგრძელებლად წაშალეთ იგი.',
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
              'პროდუქტზე "$productTitle" მარაგში მხოლოდ $availableStock $unit-ია',
            );
            return;
          case CartValidationValid():
            break;
        }

        requireAddress(
          context,
          ref: ref,
          onAddressPresent: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CheckoutScreen(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = cartItems.subtotal;
    final isMinimumMet = cartItems.isMinimumMet;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isExpanded
            ? const Border(top: BorderSide(color: Color(0xFFF3F4F6)))
            : null,
      ),
      child: Row(
        children: [
          // Total price with animated rotating chevron
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
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
                    turns: Tween(begin: 0.0, end: 0.5).animate(expandAnimation),
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
                onPressed: () => _onCheckoutPressed(context, ref),
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
    );
  }
}
