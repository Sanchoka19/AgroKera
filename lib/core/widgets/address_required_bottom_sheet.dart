import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/primary_button.dart';
import 'package:agrokera/features/profile/presentation/providers/user_address_provider.dart';
import 'package:agrokera/features/profile/presentation/screens/my_addresses_screen.dart';

/// Centralized Address Guard function.
/// If user has a saved personal delivery address, executes [onAddressPresent].
/// Otherwise, presents the [AddressRequiredBottomSheet].
void requireAddress(
  BuildContext context, {
  required WidgetRef ref,
  required VoidCallback onAddressPresent,
}) {
  final addressState = ref.read(userAddressProvider);
  if (addressState.hasAddress) {
    onAddressPresent();
  } else {
    AddressRequiredBottomSheet.show(context);
  }
}

/// Bottom Sheet prompt displayed when a user attempts to checkout without
/// having configured a delivery address in "ჩემი მისამართი".
class AddressRequiredBottomSheet extends ConsumerWidget {
  const AddressRequiredBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: const AddressRequiredBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Header Row: Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'მიუთითეთ მისამართი',
                    style: AppTypography.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subtitle description
          Text(
            'შეკვეთის გასაფორმებლად აუცილებელია მიუთითოთ თქვენი მიტანის მისამართი, რათა კურიერმა შეძლოს პროდუქტის მოწოდება.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Informational note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'თქვენ შეძლებთ მისამართის რუკაზე მონიშვნას ან GPS-ით ავტოდადგენას.',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 12,
                      height: 1.35,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary CTA Button
          PrimaryButton(
            text: 'მისამართის დამატება',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyAddressesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

