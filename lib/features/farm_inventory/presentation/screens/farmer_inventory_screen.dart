import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../providers/farmer_inventory_provider.dart';
import '../widgets/inventory_product_card.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/restock_bottom_sheet.dart';

/// Full Farmer Inventory & Stock Management Screen ("მარაგის მართვა")
/// Clean UI screen — business logic lives in `farmerInventoryProvider`,
/// and complex sheets/cards live in dedicated widgets under `presentation/widgets/`.
class FarmerInventoryScreen extends ConsumerStatefulWidget {
  final bool openAddOnStart;

  const FarmerInventoryScreen({
    super.key,
    this.openAddOnStart = false,
  });

  @override
  ConsumerState<FarmerInventoryScreen> createState() =>
      _FarmerInventoryScreenState();
}

class _FarmerInventoryScreenState extends ConsumerState<FarmerInventoryScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openAddOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ProductFormSheet.show(context);
      });
    }
  }

  Future<void> _confirmToggleAvailability(
    ProductModel product,
    bool isAvailable,
  ) async {
    final confirmed = await AppConfirmationBottomSheet.show(
      context: context,
      title: isAvailable ? 'პროდუქტის გააქტიურება' : 'პროდუქტის გათიშვა',
      message: isAvailable
          ? 'ნამდვილად გსურთ "${product.title}"-ის გაყიდვაში ჩართვა?'
          : 'ნამდვილად გსურთ "${product.title}"-ის დროებით გათიშვა? მყიდველები მას აღარ დაინახავენ.',
      confirmText: isAvailable ? 'ჩართვა' : 'გათიშვა',
      cancelText: 'უკან',
      type: isAvailable ? ConfirmationType.positive : ConfirmationType.warning,
      icon: isAvailable ? LucideIcons.checkCircle2 : LucideIcons.eyeOff,
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(farmerInventoryProvider.notifier)
        .toggleAvailability(product, isAvailable);
    if (!mounted) return;
    AppToast.info(
      context,
      isAvailable
          ? 'პროდუქტი "${product.title}" გააქტიურდა'
          : 'პროდუქტი "${product.title}" დროებით გაითიშა',
    );
  }

  Future<void> _confirmDeleteProduct(ProductModel product) async {
    final confirmed = await AppConfirmationBottomSheet.show(
      context: context,
      title: 'პროდუქტის წაშლა',
      message:
          'ნამდვილად გსურთ პროდუქტის "${product.title}" სრულად წაშლა მარაგიდან?',
      confirmText: 'წაშლა',
      cancelText: 'უკან',
      type: ConfirmationType.destructive,
      icon: LucideIcons.trash2,
    );
    if (!confirmed || !mounted) return;

    await ref.read(farmerInventoryProvider.notifier).deleteProduct(product.id);
    if (!mounted) return;
    AppToast.info(
      context,
      'პროდუქტი "${product.title}" წაიშალა',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(farmerInventoryProvider);
    final notifier = ref.read(farmerInventoryProvider.notifier);
    final filtered = inventoryState.filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ProductFormSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(
          'ახალი პროდუქტი',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'მარაგის მართვა',
              showBack: true,
              showNotificationBell: false,
              showCart: false,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              actions: [
                InkWell(
                  onTap: () => ProductFormSheet.show(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'დამატება',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    filter: InventoryFilter.all,
                    selected: inventoryState.selectedFilter,
                    label: 'ყველა (${inventoryState.allCount})',
                    onTap: () => notifier.setFilter(InventoryFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    filter: InventoryFilter.active,
                    selected: inventoryState.selectedFilter,
                    label: 'მარაგშია (${inventoryState.activeCount})',
                    onTap: () => notifier.setFilter(InventoryFilter.active),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    filter: InventoryFilter.low,
                    selected: inventoryState.selectedFilter,
                    label: 'იწურება (${inventoryState.lowCount})',
                    onTap: () => notifier.setFilter(InventoryFilter.low),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    filter: InventoryFilter.out,
                    selected: inventoryState.selectedFilter,
                    label: 'გათიშული/0 (${inventoryState.outCount})',
                    onTap: () => notifier.setFilter(InventoryFilter.out),
                  ),
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'ამ ფილტრით პროდუქტი არ მოიძებნა',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return InventoryProductCard(
                          product: product,
                          onToggleAvailability: (val) =>
                              _confirmToggleAvailability(product, val),
                          onEdit: () =>
                              ProductFormSheet.show(context, existing: product),
                          onRestock: () =>
                              RestockBottomSheet.show(context, product),
                          onDelete: () => _confirmDeleteProduct(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required InventoryFilter filter,
    required InventoryFilter selected,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = filter == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
