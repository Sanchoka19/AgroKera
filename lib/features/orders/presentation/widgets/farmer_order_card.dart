import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../screens/farmer_order_detail_screen.dart';

/// Single Order Card on the Incoming Orders screen
class FarmerOrderCard extends StatelessWidget {
  final FarmerOrder order;
  final VoidCallback? onAccept;
  final void Function(String reason)? onCancel;

  const FarmerOrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onCancel,
  });

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FarmerOrderDetailScreen(orderId: order.id),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
    final reason = await AppReasonBottomSheet.show(
      context: context,
      title: 'შეკვეთის გაუქმება',
      subtitle: 'შეკვეთა #${order.id} • გთხოვთ მიუთითოთ მიზეზი',
      confirmButtonText: 'დადასტურება',
      confirmButtonColor: const Color(0xFFDC2626),
      icon: LucideIcons.alertTriangle,
      reasons: AppReasonBottomSheet.defaultOrderCancellationReasons,
    );

    if (reason != null && context.mounted) {
      if (onCancel != null) {
        onCancel!(reason);
      }
    }
  }

  void _showDocumentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F7EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.fileText,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ელექტრონული ზედნადები',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'შეკვეთა #${order.id}',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDocRow('RS.GE ზედნადების №', 'WN-948271034'),
                      const Divider(height: 18, color: Color(0xFFE2E8F0)),
                      _buildDocRow('შემკვეთი', order.customerName),
                      const Divider(height: 18, color: Color(0xFFE2E8F0)),
                      _buildDocRow('სრული თანხა', '₾${order.totalAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AppToast.success(context, 'ზედნადები ჩამოტვირთულია PDF ფორმატში');
                  },
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: Text(
                    'PDF-ის ჩამოტვირთვა',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.color;
    final isCompleted = order.status == OrderStatus.completed;
    final isPending = order.status == OrderStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openDetails(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Colored Indicator Stripe
                Container(
                  height: 4,
                  color: statusColor,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Dot + ID & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'შეკვეთის ID',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    '#${order.id}',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.status.badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status.label,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Products & Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'პროდუქტი',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  order.productsSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ჯამი',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '₾${order.totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Customer & Date Meta
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.user,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(order.createdAt),
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Action Buttons
                      if (isPending) ...[
                        // 1. Top Row: Full-width Details Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openDetails(context),
                            icon: const Icon(
                              LucideIcons.eye,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            label: Text(
                              'დეტალები',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(
                                color: Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              minimumSize: const Size(double.infinity, 38),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 2. Bottom Row: Cancel & Accept Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _handleCancel(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  side: const BorderSide(
                                    color: Color(0xFFFECACA),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 38),
                                ),
                                child: Text(
                                  'გაუქმება',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onAccept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 38),
                                ),
                                child: Text(
                                  'დათანხმება',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            // Standard Details Outline Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openDetails(context),
                                icon: const Icon(LucideIcons.eye, size: 15),
                                label: Text(
                                  'დეტალები',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 38),
                                ),
                              ),
                            ),

                            // Document Icon Button (Completed only)
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showDocumentSheet(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    LucideIcons.fileText,
                                    size: 17,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} • $hour:$minute';
  }
}

