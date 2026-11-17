import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
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

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UserAddress address,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'მისამართის წაშლა',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'ნამდვილად გსურთ "${address.title}" (${address.formattedAddress}) მისამართის წაშლა?',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13.5,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'გაუქმება',
              style: GoogleFonts.notoSansGeorgian(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(userAddressProvider.notifier).deleteAddress(address.id);
              AppToast.info(context, 'მისამართი წაიშალა');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'წაშლა',
              style: GoogleFonts.notoSansGeorgian(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
            tooltip: 'ახალი მისამართი',
            onPressed: () => _openAddEditSheet(context, ref),
          ),
        ],
      ),
      body: addressState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addressState.addresses.isEmpty
              ? EmptyAddressesView(
                  onAddAddress: () => _openAddEditSheet(context, ref),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    // Dynamic active address indicator card
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'მიმდინარე აქტიური მისამართი:',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  addressState.activeAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

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
      floatingActionButton: addressState.addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openAddEditSheet(context, ref),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                'ახალი მისამართი',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }
}
