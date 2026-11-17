import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Card showing list of products in the order and the complete financial summary.
class OrderProductsBreakdownCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(
            'პროდუქტები და ანგარიშსწორება',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} (${item.quantityText})',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    '₾${item.price.toStringAsFixed(2)}',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFE2E8F0)),
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
          const Divider(height: 18, color: Color(0xFFE2E8F0)),
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

