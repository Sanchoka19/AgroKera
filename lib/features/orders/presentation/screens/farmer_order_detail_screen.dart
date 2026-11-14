import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirmation_bottom_sheet.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';

/// Detailed view of a farmer order matching the Figma mockups
class FarmerOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const FarmerOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<FarmerOrderDetailScreen> createState() =>
      _FarmerOrderDetailScreenState();
}

class _FarmerOrderDetailScreenState
    extends ConsumerState<FarmerOrderDetailScreen> {
  Timer? _ticker;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    // Run 1-second ticker for live countdown and 5-second live backend sync
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tickCount++;
      if (_tickCount % 5 == 0) {
        unawaited(ref.read(farmerOrdersProvider.notifier).refreshFromBackend());
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onCompleteOrder(FarmerOrder order) async {
    final confirmed = await AppConfirmationBottomSheet.showCompleteOrder(
      context: context,
      orderId: order.id,
    );

    if (confirmed && mounted) {
      ref.read(farmerOrdersProvider.notifier).completeOrder(order.id);
      AppToast.success(
        context,
        'შეკვეთა #${order.id} წარმატებით დასრულდა!',
      );
    }
  }

  Future<void> _onCancelOrder(FarmerOrder order) async {
    final reason = await AppReasonBottomSheet.show(
      context: context,
      title: 'შეკვეთის გაუქმება',
      subtitle: 'შეკვეთა #${order.id} • გთხოვთ მიუთითოთ მიზეზი',
      confirmButtonText: 'დადასტურება',
      confirmButtonColor: const Color(0xFFDC2626),
      icon: LucideIcons.alertTriangle,
      reasons: AppReasonBottomSheet.defaultOrderCancellationReasons,
    );

    if (reason != null && mounted) {
      ref.read(farmerOrdersProvider.notifier).cancelOrder(order.id, reason: reason);
      AppToast.info(context, 'შეკვეთა #${order.id} გაუქმებულია');
    }
  }

  Future<void> _onRequestCancellation(FarmerOrder order) async {
    final reason = await AppReasonBottomSheet.show(
      context: context,
      title: 'გაუქმების მოთხოვნა',
      subtitle: 'შეკვეთა #${order.id} • მოთხოვნა გადაეგზავნება ადმინისტრაციას',
      confirmButtonText: 'მოთხოვნის გაგზავნა',
      confirmButtonColor: const Color(0xFFEA580C),
      icon: LucideIcons.send,
      reasons: AppReasonBottomSheet.defaultOrderCancellationReasons,
    );

    if (reason != null && mounted) {
      AppToast.success(
        context,
        'გაუქმების მოთხოვნა მიზეზით: "$reason" გაგზავნილია ადმინისტრაციასთან',
      );
    }
  }

  void _onContactCustomer(FarmerOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'დამკვეთთან დაკავშირება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.customerName} (${order.contactPerson})',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AppToast.success(context, 'მიმდინარეობს დარეკვა: ${order.contactPhone}');
                  },
                  icon: const Icon(LucideIcons.phoneCall, size: 18),
                  label: Text(
                    'დარეკვა (${order.contactPhone})',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(farmerOrdersProvider);
    final order = ordersState.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => ordersState.orders.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'შეკვეთა #${order.id}',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // SECTION 1: შეკვეთის მიმოხილვა
            // ==========================================
            _buildSectionHeader('შეკვეთის მიმოხილვა'),
            const SizedBox(height: 10),
            _buildOverviewRow('შეკვეთის თარიღი', _formatDate(order.createdAt), isAccent: true),
            const SizedBox(height: 8),
            _buildOverviewRow('სტატუსი', order.status.label, valueColor: order.status.color),
            const SizedBox(height: 18),

            // Cancellation Notice Banner (If cancelled)
            if (order.status == OrderStatus.cancelled) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shoppingCart,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'შეკვეთა გაუქმდა ${order.cancellationReason ?? 'მარაგის არ არსებობის გამო'}',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ==========================================
            // SECTION 2: მომხმარებლის ინფორმაცია
            // ==========================================
            _buildSectionHeader('მომხმარებლის ინფორმაცია'),
            const SizedBox(height: 10),
            _buildInfoRow('შემკვეთი', order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow('საკონტაქტო პირი', order.contactPerson),
            const SizedBox(height: 18),

            // ==========================================
            // SECTION 3: პროდუქტის დეტალები
            // ==========================================
            _buildSectionHeader('პროდუქტის დეტალები'),
            const SizedBox(height: 12),
            ...order.items.map((item) => _buildProductRow(item)),

            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            // Subtotal
            _buildPriceRow('შუალედური ჯამი', '₾${order.subtotal.toStringAsFixed(2)}'),

            // Dynamic VAT (18%)
            if (order.hasVat) ...[
              const SizedBox(height: 8),
              _buildPriceRow('დღგ (18%)', '₾${order.vatAmount.toStringAsFixed(2)}'),
            ],

            const SizedBox(height: 10),
            // Total Sum
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'სრული ჯამი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '₾${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==========================================
            // SECTION 4: მიწოდების ინფორმაცია
            // ==========================================
            if (order.deliveryTimeWindow != null || order.deliveryAddress != null) ...[
              _buildSectionHeader('მიწოდების ინფორმაცია'),
              const SizedBox(height: 12),
              if (order.deliveryTimeWindow != null)
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      order.deliveryTimeWindow!,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),

      // Docked Sticky Bottom Actions
      bottomNavigationBar: _buildBottomActions(order),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSansGeorgian(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, {Color? valueColor, bool isAccent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            color: isAccent ? AppColors.primary : const Color(0xFF64748B),
            fontWeight: isAccent ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(FarmerOrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'რაოდენობა: ${item.quantityText}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₾${item.price.toStringAsFixed(2)}',
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  /// Compact, ergonomic bottom action bar
  Widget? _buildBottomActions(FarmerOrder order) {
    if (order.status == OrderStatus.completed || order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: OutlinedButton.icon(
            onPressed: () => _onContactCustomer(order),
            icon: const Icon(LucideIcons.phone, size: 18),
            label: Text(
              'დამკვეთთან დაკავშირება',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      );
    }

    // In Progress Actions
    if (order.status == OrderStatus.inProgress) {
      final canDirectCancel = order.canDirectlyCancel;
      final remainingTime = order.remainingCancellationTime;
      final cancelLabel = canDirectCancel
          ? 'გაუქმება ${_formatCountdown(remainingTime)}'
          : 'გაუქმების მოთხოვნა';

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Primary: შეკვეთის დასრულება
              ElevatedButton(
                onPressed: () => _onCompleteOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'შეკვეთის დასრულება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 2. Secondary Row: Cancel & Call
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (canDirectCancel) {
                          _onCancelOrder(order);
                        } else {
                          _onRequestCancellation(order);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        cancelLabel,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onContactCustomer(order),
                      icon: const Icon(LucideIcons.phone, size: 16),
                      label: Text(
                        'დაკავშირება',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Pending Order Actions
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onCancelOrder(order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'გაუქმება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(farmerOrdersProvider.notifier).acceptOrder(order.id);
                  AppToast.success(context, 'შეკვეთა #${order.id} მიღებულია!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'შეკვეთის მიღება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

