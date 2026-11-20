import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Card showing concise, clear financial breakdown for the farmer.
class FarmerOrderFinancialCard extends StatelessWidget {
  final FarmerOrder order;

  const FarmerOrderFinancialCard({
    super.key,
    required this.order,
  });

  Widget _buildRow(String label, String value, {bool isMuted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12.5,
              color: isMuted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.receiptText,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ანგარიშსწორების დეტალები',
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
          const SizedBox(height: 12),

          // Subtotal
          _buildRow('პროდუქციის ჯამი', '₾${order.subtotal.toStringAsFixed(2)}'),

          // Delivery fee
          if (order.isPickup) ...[
            _buildRow('მიტანის მეთოდი', 'თვითგატანა (0.00 ₾)'),
          ] else if (order.deliveryFee > 0) ...[
            _buildRow('მიტანის საფასური', '₾${order.deliveryFee.toStringAsFixed(2)}'),
          ],

          // Heavy Cargo fee
          if (order.heavyFee > 0) ...[
            _buildRow('სატვირთო მომსახურება', '₾${order.heavyFee.toStringAsFixed(2)}'),
          ],

          // Platform fee
          if (order.platformFee > 0) ...[
            _buildRow('სერვისის საკომისიო', '₾${order.platformFee.toStringAsFixed(2)}'),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Total payout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'სრული ჯამი',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      order.isBankTransfer
                          ? 'AgroKera Escrow გადარიცხვა'
                          : 'ნაღდი ანგარიშსწორება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₾${order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

