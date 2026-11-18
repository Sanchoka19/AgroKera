import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_confirmation_bottom_sheet.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';
import 'package:agrokera/features/profile/presentation/providers/user_address_provider.dart';
import 'package:agrokera/features/profile/presentation/widgets/addresses/address_card_tile.dart';
import 'package:agrokera/features/profile/presentation/widgets/addresses/add_edit_address_sheet.dart';
import 'package:agrokera/features/profile/presentation/widgets/addresses/empty_addresses_view.dart';

/// Screen displaying and managing user delivery and farm locations.
class MyAddressesScreen extends ConsumerWidget {
  const MyAddressesScreen({super.key});

  void _openAddEditSheet(
    BuildContext context,
    WidgetRef ref, [
    UserAddress? address,
  ]) {
    final notifier = ref.read(userAddressProvider.notifier);
    AddEditAddressSheet.show(
      context: context,
      initialAddress: address,
      onDetectGps: notifier.detectGpsAddress,
      onSave: (saved) {
        if (address == null) {
          notifier.addAddress(saved);
          AppToast.success(context, 'ახალი მისამართი წარმატებით დაემატა');
        } else {
          notifier.updateAddress(saved);
          AppToast.success(context, 'მისამართი წარმატებით განახლდა');
        }
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UserAddress address,
  ) async {
    final confirmed = await AppConfirmationBottomSheet.showDeleteAddress(
      context: context,
      addressTitle: address.title,
      addressDetails: address.formattedAddress,
    );

    if (!confirmed || !context.mounted) return;

    ref.read(userAddressProvider.notifier).deleteAddress(address.id);
    if (context.mounted) {
      AppToast.info(context, 'მისამართი წაიშალა');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(userAddressProvider);
    final notifier = ref.read(userAddressProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ჩემი მისამართები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: addressState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addressState.addresses.isEmpty
              ? EmptyAddressesView(
                  onAddAddress: () => _openAddEditSheet(context, ref),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    // List of address cards
                    ...addressState.addresses.map((addr) {
                      return AddressCardTile(
                        key: ValueKey(addr.id),
                        address: addr,
                        onSetDefault: () {
                          notifier.setDefaultAddress(addr.id);
                          AppToast.success(
                            context,
                            'ძირითად მისამართად დაყენდა: ${addr.title}',
                          );
                        },
                        onEdit: () => _openAddEditSheet(context, ref, addr),
                        onDelete: () => _confirmDelete(context, ref, addr),
                      );
                    }),
                  ],
                ),
      bottomNavigationBar: addressState.addresses.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAddEditSheet(context, ref),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(
                        'ახალი მისამართის დამატება',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
