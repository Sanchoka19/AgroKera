import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/auth_required_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/mock_data.dart';
import '../../data/models/product_model.dart';
import '../../../cart_checkout/data/models/cart_item_model.dart';
import '../../../cart_checkout/presentation/providers/cart_provider.dart';
import '../../../cart_checkout/presentation/screens/cart_screen.dart';
import '../providers/favorites_provider.dart';
import 'farmer_profile_screen.dart';

/// Product Details Screen adhering to specification:
/// - Large photo header
/// - Product title, farmer info link, star rating & stock badge
/// - Quantity selector (- 1 +)
/// - Delivery/Price info block with #EBF7EF soft leaf tint
/// - Rich description
/// - Sticky bottom bar with Price & "კალათაში დამატება" (Guest protected)
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final totalPrice = product.price * _quantity;

    // Find farmer
    final farmer = MockData.farmers.firstWhere(
      (f) => f.id == product.farmerId,
      orElse: () => MockData.farmers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Large Photo Sliver App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isFav = ref.watch(favoritesProvider).contains(product.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : LucideIcons.heart,
                          color: isFav
                              ? AppColors.accentWarm
                              : AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          requireAuth(
                            context,
                            ref: ref,
                            onAuthenticated: () {
                              ref.read(favoritesProvider.notifier).toggle(product.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.surfaceInput,
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppColors.textSecondary,
                                  size: 48,
                                ),
                              ),
                        )
                      : Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.surfaceInput,
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppColors.textSecondary,
                                  size: 48,
                                ),
                              ),
                        ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: AppTypography.h1.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Farmer link
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              FarmerProfileScreen(farmer: farmer),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.store,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.farmerName,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating & Stock Row
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: AppColors.rating,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewCount} შეფასება)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      StatusBadge.success(
                        label: product.stockStatus,
                        icon: const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quantity Selector & Unit Price Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'რაოდენობა (${product.unit}):',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            // Decrement
                            InkWell(
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.minus,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                '$_quantity',
                                style: AppTypography.titleMedium.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // Increment
                            InkWell(
                              onTap: () {
                                setState(() => _quantity++);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.plus,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Delivery Info Block with #EBF7EF Soft Leaf Tint
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.truck,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'მიწოდების მეთოდები',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• ფერმერის თვითმიწოდება (რეგიონის მიხედვით)\n• ადგილზე გატანა (Self Pickup — მეურნეობიდან)',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.shieldCheck,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '100% ნატურალური და ბიო-სუფთა პროდუქტი',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Description Section
                  Text(
                    'აღწერა',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      // Sticky Bottom Bar: Total Price + Add to Cart Button (Protected) + Overlapping Discount Badge
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'სულ გადასახდელი:',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₾${totalPrice.toStringAsFixed(2)}',
                          style: AppTypography.h1.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.effectiveOriginalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₾${(product.effectiveOriginalPrice! * _quantity).toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: PrimaryButton(
                    text: 'დამატება',
                    icon: const Icon(
                      LucideIcons.shoppingBag,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      requireAuth(
                        context,
                        ref: ref,
                        onAuthenticated: () {
                          ref.read(cartProvider.notifier).addItem(
                                CartItemModel(
                                  id: product.id,
                                  title: product.title,
                                  packageText: '${product.unit} შეფუთვა',
                                  farmerName: product.farmerName,
                                  pricePerUnit: product.price,
                                  unit: product.unit,
                                  imageUrl: product.imageUrl,
                                  quantity: _quantity,
                                  weightKg: _quantity.toDouble(),
                                ),
                              );

                          AppToast.success(
                            context,
                            '$_quantity ${product.unit} ${product.title} დამატებულია კალათაში!',
                            actionLabel: 'კალათა',
                            onAction: () {
                              requireAuth(
                                context,
                                ref: ref,
                                onAuthenticated: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CartScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Overlapping Discount Badge: half outside top border, half inside above button
          if (product.discountPercent != null)
            Positioned(
              top: -12,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentWarm,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentWarm.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.tag,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '-${product.discountPercent}% ფასდაკლება',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
