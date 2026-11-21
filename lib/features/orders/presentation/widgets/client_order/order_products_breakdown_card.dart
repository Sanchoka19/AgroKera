import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_cached_image.dart';
import '../../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Card showing list of products in the order and the complete financial summary.
/// Redesigned with product photo thumbnail first, then title, quantity badge, and price.
class OrderProductsBreakdownCard extends ConsumerWidget {
  final FarmerOrder order;

  const OrderProductsBreakdownCard({super.key, required this.order});

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildProductThumbnail(String? url) {
    return AppCachedImage(
      imageUrl: url,
      width: 44,
      height: 44,
      borderRadius: BorderRadius.circular(10),
      fallbackIcon: LucideIcons.package,
      backgroundColor: const Color(0xFFF8FAFC),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketplace = ref.watch(marketplaceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.packageCheck,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'პროდუქტები და ანგარიშსწორება',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${order.items.length} სახეობა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Product items list with photo first, then name and highlighted quantity badge
          ...order.items.map(
            (item) {
              final matchedProduct = marketplace.products.where((p) =>
                  (item.productId != null && p.id == item.productId) ||
                  p.title.trim().toLowerCase() == item.name.trim().toLowerCase()
              ).firstOrNull;
              final effectiveImageUrl = (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
                  ? item.imageUrl!.trim()
                  : matchedProduct?.imageUrl;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product item thumbnail photo
                    _buildProductThumbnail(effectiveImageUrl),
                    const SizedBox(width: 12),

                    // Title & highlighted quantity badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Text(
                                  'რაოდენობა: ${item.quantityText}',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Total Item Price
                    Text(
                      '₾${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _buildSummaryRow(
            'პროდუქტების ჯამი',
            '₾${order.subtotal.toStringAsFixed(2)}',
          ),
          if (order.hasVat) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'დღგ (18%)',
              '₾${order.vatAmount.toStringAsFixed(2)}',
            ),
          ],
          if (order.isPickup) ...[
            const SizedBox(height: 4),
            _buildSummaryRow('მიტანა', 'თვითგატანა (0 ₾)'),
          ] else if (order.deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'მიტანის საფასური',
              '₾${order.deliveryFee.toStringAsFixed(2)}',
            ),
          ],
          if (order.heavyFee > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'სატვირთო გადაზიდვა',
              '₾${order.heavyFee.toStringAsFixed(2)}',
            ),
          ],
          if (order.platformFee > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'სერვისის საკომისიო',
              '₾${order.platformFee.toStringAsFixed(2)}',
            ),
          ],
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'სულ გადასახდელი',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '₾${order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
