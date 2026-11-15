import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Style preset for confirmation actions
enum ConfirmationType {
  /// Destructive actions: Logout, Delete item, Clear cart, Delete account
  destructive,

  /// Warning / Attention actions: Discard unsaved changes, Cancel operation
  warning,

  /// Milestone / Positive confirmations: Complete order, Accept delivery
  positive,
}

/// Universal, mobile-first Confirmation Bottom Sheet.
/// Replaces clunky center alert dialogs for critical user decisions.
class AppConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final ConfirmationType type;
  final IconData? icon;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'დადასტურება',
    this.cancelText = 'უკან',
    this.type = ConfirmationType.destructive,
    this.icon,
    required this.onConfirm,
    this.onCancel,
  });

  /// Static helper to display the sheet modally and return `true` if confirmed, `false` otherwise.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'დადასტურება',
    String cancelText = 'უკან',
    ConfirmationType type = ConfirmationType.destructive,
    IconData? icon,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AppConfirmationBottomSheet(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          type: type,
          icon: icon,
          onConfirm: () => Navigator.of(ctx).pop(true),
          onCancel: () => Navigator.of(ctx).pop(false),
        ),
      ),
    );

    return result ?? false;
  }

  /// Preset for logging out
  static Future<bool> showLogout({
    required BuildContext context,
  }) {
    return show(
      context: context,
      title: 'ანგარიშიდან გამოსვლა',
      message: 'ნამდვილად გსურთ სისტემიდან გამოსვლა? ხელახლა შემოსასვლელად დაგჭირდებათ ავტორიზაცია.',
      confirmText: 'გამოსვლა',
      cancelText: 'დარჩენა',
      type: ConfirmationType.destructive,
      icon: LucideIcons.logOut,
    );
  }

  /// Preset for attempting to add an item from a different farmer in Single-Vendor Cart
  static Future<bool> showDifferentFarmerCart({
    required BuildContext context,
    required String currentFarmerName,
    required String newFarmerName,
  }) {
    return show(
      context: context,
      title: 'განსხვავებული ფერმერი',
      message:
          'კალათში უკვე გაქვთ „$currentFarmerName“-ს პროდუქტები. გსურთ კალათის გასუფთავება და ახალი ფერმერის პროდუქტის დამატება?',
      confirmText: 'კალათის გასუფთავება და დამატება',
      cancelText: 'გაუქმება',
      type: ConfirmationType.warning,
      icon: LucideIcons.shoppingBag,
    );
  }

  /// Preset for clearing the shopping cart
  static Future<bool> showClearCart({
    required BuildContext context,
  }) {
    return show(
      context: context,
      title: 'კალათის გასუფთავება',
      message: 'ნამდვილად გსურთ კალათიდან ყველა პროდუქტის წაშლა?',
      confirmText: 'გასუფთავება',
      cancelText: 'უკან',
      type: ConfirmationType.destructive,
      icon: LucideIcons.trash2,
    );
  }

  /// Preset for completing an order
  static Future<bool> showCompleteOrder({
    required BuildContext context,
    required String orderId,
  }) {
    return show(
      context: context,
      title: 'შეკვეთის დასრულება',
      message: 'დაადასტურეთ, რომ შეკვეთა #$orderId ჩაბარდა შემკვეთს და მიწოდება წარმატებით დასრულდა.',
      confirmText: 'დასრულება',
      cancelText: 'უკან',
      type: ConfirmationType.positive,
      icon: LucideIcons.checkCircle2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (Color badgeBg, Color accentColor, IconData defaultIcon) = switch (type) {
      ConfirmationType.destructive => (
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        LucideIcons.alertTriangle,
      ),
      ConfirmationType.warning => (
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
        LucideIcons.alertCircle,
      ),
      ConfirmationType.positive => (
        const Color(0xFFE8F7EE),
        AppColors.primary,
        LucideIcons.checkCircle2,
      ),
    };

    final effectiveIcon = icon ?? defaultIcon;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top drag handle
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

            // Visual Status Icon Badge (Centered)
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    effectiveIcon,
                    size: 26,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            // Message description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13.5,
                  height: 1.45,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons: Stacked or Side-by-Side
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm CTA
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
