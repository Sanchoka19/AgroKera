import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../screens/farmer_order_detail_screen.dart';
import '../screens/order_chat_screen.dart';

/// Modern, ergonomic Order Card on the Incoming Orders screen
class FarmerOrderCard extends StatelessWidget {
  final FarmerOrder order;
  final VoidCallback? onAccept;
  final void Function(String reason)? onCancel;
  final bool isUpdating;

  const FarmerOrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onCancel,
    this.isUpdating = false,
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
                    AppToast.success(
                      context,
                      'ზედნადები ჩამოტვირთულია PDF ფორმატში',
                      icon: LucideIcons.fileCheck,
                    );
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
    final statusColor = order.status.color;
    final isCompleted = order.status == OrderStatus.completed;
    final isPending = order.status == OrderStatus.pending;
    final isCancelled = order.status == OrderStatus.cancelled;

    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final extraItemsCount = order.items.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: isCancelled ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isCancelled ? 0.02 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                // Top Color Stripe
                Container(
                  height: 3.5,
                  color: statusColor,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: #ID + Date & Status Badge + Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  '#${order.id}',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '• ${_formatDate(order.createdAt)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: order.status.badgeBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(order.status),
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.status.label,
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),

                      // Middle: Product & Total Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Product info + Customer name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        firstItem?.name ?? 'პროდუქცია',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    if (firstItem != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: Text(
                                          firstItem.quantityText,
                                          style: GoogleFonts.notoSansGeorgian(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (extraItemsCount > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '+ კიდევ $extraItemsCount პროდუქტი',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.user,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order.customerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Right: Price & Payment Method Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₾${order.totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    order.isBankTransfer
                                        ? LucideIcons.shieldCheck
                                        : LucideIcons.banknote,
                                    size: 12,
                                    color: order.isBankTransfer
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    order.isBankTransfer ? 'Escrow' : 'ნაღდი',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: order.isBankTransfer
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // In Progress Escrow Banner (if applicable)
                      if (order.status == OrderStatus.inProgress &&
                          order.isBankTransfer) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: order.isPaymentConfirmed
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: order.isPaymentConfirmed
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                order.isPaymentConfirmed
                                    ? LucideIcons.shieldCheck
                                    : LucideIcons.alertTriangle,
                                size: 14,
                                color: order.isPaymentConfirmed
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.isPaymentConfirmed
                                      ? 'თანხა დაცულია Escrow-ში • მოამზადეთ'
                                      : (order.hasClientReportedPayment
                                          ? 'გადარიცხვა მოწმდება სისტემაში'
                                          : 'თანხის ასახვის მოლოდინში'),
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: order.isPaymentConfirmed
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF92400E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Cancelled Reason Note (if cancelled)
                      if (isCancelled && order.cancellationReason != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.alertCircle,
                              size: 13,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'მიზეზი: ${order.cancellationReason}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Bottom Actions
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleCancel(context),
                                icon: const Icon(LucideIcons.x, size: 14),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  side: const BorderSide(
                                    color: Color(0xFFFECACA),
                                    width: 1.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 36),
                                ),
                                label: Text(
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
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isUpdating ? null : onAccept,
                                icon: isUpdating
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(LucideIcons.check, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 36),
                                ),
                                label: Text(
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openDetails(context),
                                icon: const Icon(LucideIcons.eye, size: 14),
                                label: Text(
                                  'დეტალები',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF334155),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 36),
                                ),
                              ),
                            ),

                            // Chat Icon Button (Pending & In Progress)
                            if (order.status == OrderStatus.inProgress) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OrderChatScreen(order: order),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                      width: 1.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.messageSquare,
                                      size: 15,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Document Icon Button (Completed only)
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showDocumentSheet(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 1.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    LucideIcons.fileText,
                                    size: 16,
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
