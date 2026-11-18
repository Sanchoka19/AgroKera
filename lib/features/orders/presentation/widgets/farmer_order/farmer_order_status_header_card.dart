import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Header card displaying order status, creation date, and payment assurance info
class FarmerOrderStatusHeaderCard extends StatelessWidget {
  final FarmerOrder order;

  const FarmerOrderStatusHeaderCard({
    super.key,
    required this.order,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year} • $hour:$minute';
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.clock;
      case OrderStatus.inProgress:
        return LucideIcons.truck;
      case OrderStatus.completed:
        return LucideIcons.checkCheck;
      case OrderStatus.cancelled:
        return LucideIcons.alertCircle;
    }
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
          // Section Title
          Text(
            'შეკვეთის მიმოხილვა',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDate(order.createdAt),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: order.status.badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: order.status.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(order.status),
                      size: 13,
                      color: order.status.color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      order.status.label,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: order.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Payment Assurance Status
          if (order.isBankTransfer) ...[
            _buildEscrowStatusBanner(),
          ] else ...[
            _buildCashStatusBanner(),
          ],

          // Cancellation Notice (if cancelled)
          if (order.status == OrderStatus.cancelled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'შეკვეთა გაუქმდა ${order.cancellationReason ?? 'მარაგის არ არსებობის გამო'}',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEscrowStatusBanner() {
    final bool isConfirmed = order.isPaymentConfirmed;
    final bool isReported = order.hasClientReportedPayment;

    final Color bgColor = isConfirmed
        ? const Color(0xFFF0FDF4)
        : (isReported ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB));
    final Color borderColor = isConfirmed
        ? const Color(0xFF86EFAC)
        : (isReported ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A));
    final Color textColor = isConfirmed
        ? const Color(0xFF166534)
        : (isReported ? const Color(0xFF1E40AF) : const Color(0xFF92400E));
    final IconData icon = isConfirmed
        ? LucideIcons.shieldCheck
        : (isReported ? LucideIcons.clock : LucideIcons.alertCircle);
    final String title = isConfirmed
        ? 'AgroKera Escrow: თანხა დაცულია'
        : (isReported
            ? 'AgroKera Escrow: გადარიცხვა მოწმდება'
            : 'AgroKera Escrow: თანხის მოლოდინში');
    final String subtitle = isConfirmed
        ? 'თანხა გარანტირებულად ჩაგერიცხებათ ჩაბარებისთანავე'
        : (isReported
            ? 'მყიდველმა გადარიცხვა დააფიქსირა, მოწმდება სისტემაში'
            : 'შეკვეთის მომზადება დაიწყეთ თანხის ასახვის შემდეგ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.banknote,
            size: 18,
            color: Color(0xFF475569),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ნაღდი ანგარიშსწორება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'თანხა ჩაიბარეთ ადგილზე პროდუქტის გადაცემისას',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
