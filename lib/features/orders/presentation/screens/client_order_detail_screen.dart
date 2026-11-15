import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';
import 'order_chat_screen.dart';

/// Clean, minimalistic client order details screen ("ჩემი შეკვეთის დეტალები")
class ClientOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ClientOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<ClientOrderDetailScreen> createState() =>
      _ClientOrderDetailScreenState();
}

class _ClientOrderDetailScreenState
    extends ConsumerState<ClientOrderDetailScreen> {
  Timer? _ticker;
  bool _isReportedLocally = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    unawaited(
      Future.microtask(
        () => ref.read(farmerOrdersProvider.notifier).refreshFromBackend(),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'იან',
      'თებ',
      'მარ',
      'აპრ',
      'მაი',
      'ივნ',
      'ივლ',
      'აგვ',
      'სექ',
      'ოქტ',
      'ნოე',
      'დეკ',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(farmerOrdersProvider);
    final order = ordersState.clientOrders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => ordersState.orders.firstWhere(
        (o) => o.id == widget.orderId,
        orElse: () => ordersState.clientOrders.isNotEmpty
            ? ordersState.clientOrders.first
            : (ordersState.orders.isNotEmpty
                ? ordersState.orders.first
                : throw StateError('Order not found')),
      ),
    );

    final isReported = order.hasClientReportedPayment || _isReportedLocally;
    final stepIndex = switch (order.status) {
      OrderStatus.pending => 1,
      OrderStatus.inProgress => 2,
      OrderStatus.completed => 3,
      OrderStatus.cancelled => 0,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'შეკვეთა #${order.id}',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare, color: AppColors.primary),
            tooltip: 'ჩათი ფერმერთან',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderChatScreen(order: order),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(farmerOrdersProvider.notifier).refreshFromBackend(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. STATUS & TIMELINE CARD
              // ==========================================
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.trackingNumber ?? 'AK-${order.id}',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(order.createdAt),
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: order.status.badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.label,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: order.status.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.status != OrderStatus.cancelled) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTrackingStep('მოლოდინში', stepIndex >= 1),
                          _buildStepConnector(stepIndex >= 2),
                          _buildTrackingStep('დადასტურდა', stepIndex >= 2),
                          _buildStepConnector(stepIndex >= 3),
                          _buildTrackingStep('ჩაბარდა', stepIndex >= 3),
                        ],
                      ),
                      if (order.status == OrderStatus.pending &&
                          order.remainingCancellationTime.inMinutes > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'ფერმერის დადასტურების ვადა: ~${order.remainingCancellationTime.inMinutes} წთ',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else if (order.cancellationReason != null &&
                        order.cancellationReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          'გაუქმების მიზეზი: ${order.cancellationReason}',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 2. ESCROW PAYMENT CARD (Only when In Progress + Bank Transfer)
              // ==========================================
              if (order.status == OrderStatus.inProgress &&
                  order.isBankTransfer) ...[
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'AgroKera Escrow ანგარიშსწორება',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCopyRow(
                        context,
                        label: 'IBAN (თიბისი ბანკი):',
                        value: 'GE29TB7553608011000018',
                      ),
                      const SizedBox(height: 8),
                      _buildCopyRow(
                        context,
                        label: 'დანიშნულების კოდი:',
                        value: order.trackingNumber ?? 'AK-${order.id}',
                        isAccent: true,
                      ),
                      const SizedBox(height: 10),
                      if (!isReported)
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _isReportedLocally = true);
                              ref
                                  .read(farmerOrdersProvider.notifier)
                                  .reportBankTransferSent(order.id);
                              AppToast.success(
                                context,
                                'გადარიცხვა დაფიქსირდა! სისტემა ამოწმებს თანხას.',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              LucideIcons.sendHorizontal,
                              size: 15,
                            ),
                            label: Text(
                              'გადარიცხვა შევასრულე',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.circleCheck,
                                size: 15,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'გადარიცხვა დაფიქსირდა • მოწმდება Escrow-ში',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // 3. HANDOVER PIN CARD (Only when In Progress)
              // ==========================================
              if (order.status == OrderStatus.inProgress) ...[
                _buildCard(
                  color: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.keyRound,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ჩაბარების PIN კოდი',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  order.deliveryPin,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E3A8A),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: order.deliveryPin),
                          );
                          AppToast.success(context, 'PIN დაკოპირდა!');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Text(
                            'კოპირება',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // 4. PRODUCTS & FINANCIAL BREAKDOWN
              // ==========================================
              _buildCard(
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
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 5. DELIVERY INFO CARD
              // ==========================================
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'მიწოდების ინფორმაცია',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.deliveryAddress ?? 'თბილისი',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.deliveryTimeWindow != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.deliveryTimeWindow!,
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.creditCard,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.isBankTransfer
                                ? 'AgroKera Escrow'
                                : 'ნაღდი ანგარიშსწორება',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(order),
    );
  }

  Widget _buildCard({
    required Widget child,
    Color color = Colors.white,
    Color borderColor = const Color(0xFFE2E8F0),
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCopyRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isAccent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAccent ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAccent ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isAccent
                        ? const Color(0xFF92400E)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              AppToast.success(context, 'დაკოპირდა!');
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'კოპირება',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildTrackingStep(String title, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.primary : const Color(0xFFCBD5E1),
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 10.5,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone ? AppColors.primary : const Color(0xFFE2E8F0),
    );
  }

  Widget? _buildBottomActions(FarmerOrder order) {
    if (order.status == OrderStatus.inProgress) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(farmerOrdersProvider.notifier)
                  .completeOrder(order.id);
              AppToast.success(
                context,
                'შეკვეთა #${order.id} დადასტურებულია როგორც ჩაბარებული!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(LucideIcons.circleCheck, size: 16),
            label: Text(
              'ჩავიბარე შეკვეთა',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    if (order.status == OrderStatus.pending || order.canDirectlyCancel) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: TextButton.icon(
            onPressed: () async {
              final reason = await AppReasonBottomSheet.show(
                context: context,
                title: 'შეკვეთის გაუქმება',
                subtitle:
                    'შეკვეთა #${order.id} • გთხოვთ აირჩიოთ გაუქმების მიზეზი',
                confirmButtonText: 'გაუქმება',
                confirmButtonColor: const Color(0xFFDC2626),
                icon: LucideIcons.alertTriangle,
                reasons: const [
                  'შემთხვევით გავაფორმე შეკვეთა',
                  'მიწოდების დრო აღარ მაწყობს',
                  'მისამართის შეცვლა მსურს',
                  'სხვა პროდუქტის არჩევა მსურს',
                ],
              );
              if (reason != null && mounted) {
                ref
                    .read(farmerOrdersProvider.notifier)
                    .cancelOrder(order.id, reason: reason);
                AppToast.info(
                  context,
                  'შეკვეთა #${order.id} გაუქმებულია ($reason)',
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LucideIcons.x, size: 16),
            label: Text(
              'შეკვეთის გაუქმება',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return null;
  }
}
