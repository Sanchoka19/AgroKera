import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_filter_tab.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../providers/farmer_inventory_provider.dart';
import '../widgets/inventory_product_card.dart';
import '../widgets/restock_bottom_sheet.dart';
import 'add_edit_product_screen.dart';

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
  void _openAddEditProduct([ProductModel? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(existing: existing),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.openAddOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAddEditProduct();
      });
    }
  }

  Future<void> _confirmToggleAvailability(
    ProductModel product,
    bool isAvailable,
  ) async {
    if (isAvailable && product.isStockBelowMinOrder) {
      AppToast.error(
        context,
        'მარაგი (${product.stockQuantity.toInt()} ${product.unit}) ნაკლებია მინიმალურ შეკვეთაზე (${product.minOrderDisplay}). გასააქტიურებლად შეავსეთ მარაგი ან შეამცირეთ მინიმალური ზღვარი.',
      );
      return;
    }

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
        onPressed: () => _openAddEditProduct(),
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
            const AppHeader(
              title: 'მარაგის მართვა',
              showBack: true,
              centerTitle: true,
              showNotificationBell: false,
              showCart: false,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            ),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  AppFilterTab(
                    label: 'ყველა',
                    count: inventoryState.allCount,
                    showZeroCount: true,
                    isSelected: inventoryState.selectedFilter == InventoryFilter.all,
                    onTap: () => notifier.setFilter(InventoryFilter.all),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    label: 'მარაგშია',
                    count: inventoryState.activeCount,
                    showZeroCount: true,
                    isSelected: inventoryState.selectedFilter == InventoryFilter.active,
                    onTap: () => notifier.setFilter(InventoryFilter.active),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    label: 'იწურება',
                    count: inventoryState.lowCount,
                    showZeroCount: true,
                    isSelected: inventoryState.selectedFilter == InventoryFilter.low,
                    onTap: () => notifier.setFilter(InventoryFilter.low),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    label: 'გათიშული/0',
                    count: inventoryState.outCount,
                    showZeroCount: true,
                    isSelected: inventoryState.selectedFilter == InventoryFilter.out,
                    onTap: () => notifier.setFilter(InventoryFilter.out),
                  ),
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppAssets.emptyProducts,
                              width: 160,
                              height: 160,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'პროდუქცია ვერ მოიძებნა',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ამ ფილტრით პროდუქტი არ მოიძებნა',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
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
                          onEdit: () => _openAddEditProduct(product),
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

}
