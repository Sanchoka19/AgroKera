import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';
import 'order_chat_screen.dart';

/// Client Orders History & Live Shipment Tracking Screen ("ჩემი შეკვეთები")
class ClientOrdersScreen extends ConsumerStatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  ConsumerState<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends ConsumerState<ClientOrdersScreen> {
  bool _showActiveOnly = false;
  Timer? _liveSyncTimer;
  final Set<String> _locallyReportedIds = {};

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref.read(farmerOrdersProvider.notifier).refreshFromBackend(),
      ),
    );
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        unawaited(ref.read(farmerOrdersProvider.notifier).refreshFromBackend());
      }
    });
  }

  @override
  void dispose() {
    _liveSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(farmerOrdersProvider);
    final allOrders = ordersState.orders;

    final orders = _showActiveOnly
        ? allOrders
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.inProgress)
            .toList()
        : allOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'ჩემი შეკვეთები',
              showBack: true,
              showNotificationBell: false,
              showCart: false,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            ),

            // Segmented Filter (ყველა / მიმდინარე)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildTabButton(
                    label: 'ყველა შეკვეთა (${allOrders.length})',
                    isSelected: !_showActiveOnly,
                    onTap: () => setState(() => _showActiveOnly = false),
                  ),
                  const SizedBox(width: 10),
                  _buildTabButton(
                    label:
                        'მიმდინარე (${allOrders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.inProgress).length})',
                    isSelected: _showActiveOnly,
                    onTap: () => setState(() => _showActiveOnly = true),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(farmerOrdersProvider.notifier).refreshFromBackend(),
                child: orders.isEmpty
                    ? Center(
                        child: Text(
                          'შეკვეთები არ მოიძებნა',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _buildClientOrderCard(order);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientOrderCard(FarmerOrder order) {
    final isReported = order.hasClientReportedPayment ||
        _locallyReportedIds.contains(order.id);
    final stepIndex = switch (order.status) {
      OrderStatus.pending => 1,
      OrderStatus.inProgress => 2,
      OrderStatus.completed => 3,
      OrderStatus.cancelled => 0,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.packageCheck,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'შეკვეთა #${order.id}',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        order.trackingNumber ?? 'AK-${order.id}',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: order.status.badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.label,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: order.status.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3-Step Order Progress Stepper (when not cancelled)
          if (order.status != OrderStatus.cancelled) ...[
            Row(
              children: [
                _buildTrackingStep('მოლოდინში', stepIndex >= 1),
                _buildStepConnector(stepIndex >= 2),
                _buildTrackingStep('დადასტურდა', stepIndex >= 2),
                _buildStepConnector(stepIndex >= 3),
                _buildTrackingStep('ჩაბარდა', stepIndex >= 3),
              ],
            ),
            if (order.status == OrderStatus.pending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 15,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.remainingCancellationTime.inMinutes > 0
                            ? 'ფერმერს დასადასტურებლად დარჩა ~${order.remainingCancellationTime.inMinutes} წუთი. თანხის გადახდა არ არის საჭირო დასტურამდე.'
                            : 'ფერმერის დადასტურების მოლოდინში. თანხის გადახდა არ არის საჭირო დასტურამდე.',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
          ] else if (order.cancellationReason != null &&
              order.cancellationReason!.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'მიზეზი: ${order.cancellationReason}',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],

          // Items summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
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
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Footer: Delivery Info & Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        order.deliveryAddress ?? 'თბილისი',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'სულ: ₾${order.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (order.totalDeliveryFee > 0)
                    Text(
                      'მიტანა: +₾${order.totalDeliveryFee.toStringAsFixed(0)}',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (order.status == OrderStatus.inProgress) ...[
            const SizedBox(height: 12),
            if (order.isBankTransfer) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ფერმერმა დაადასტურა! გადმორიცხეთ Escrow-ზე:',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IBAN (თიბისი ბანკი):',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SelectableText(
                                  'GE29TB7553608011000018',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(text: 'GE29TB7553608011000018'));
                              AppToast.success(context, 'IBAN დაკოპირდა!');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.copy,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'კოპირება',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Destination Code Card (High Prominence)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'დანიშნულება: ${order.trackingNumber ?? 'AK-${order.id}'}',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF92400E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: order.trackingNumber ?? 'AK-${order.id}'));
                                  AppToast.success(context, 'დანიშნულების კოდი დაკოპირდა!');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFCD34D)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.copy,
                                        size: 12,
                                        color: Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'კოპირება',
                                        style: GoogleFonts.notoSansGeorgian(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'მნიშვნელოვანია: მობაილ-ბანკში (TBC/BOG) გადარიცხვისას ველში „დანიშნულება“ აუცილებლად ჩასვით ეს კოდი!',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 10.5,
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isReported) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _locallyReportedIds.add(order.id);
                            });
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
                          icon: const Icon(LucideIcons.sendHorizontal, size: 15),
                          label: Text(
                            'გადარიცხვა შევასრულე',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                'გადარიცხვა დაფიქსირდა • მოწმდება AgroKera Escrow-ში',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.banknote,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ფერმერმა დაადასტურა! თანხას (₾${order.totalAmount.toStringAsFixed(2)}) გადაიხდით ნაღდი ფულით ჩაბარებისას.',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          color: const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Delivery PIN Card for Handover (High Security)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ჩაბარების PIN: ',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                          SelectableText(
                            order.deliveryPin,
                            style: GoogleFonts.firaCode(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E3A8A),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.deliveryPin));
                          AppToast.success(context, 'PIN კოდი დაკოპირდა!');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.copy,
                                size: 11,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'კოპირება',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ეს 4-ნიშნა კოდი უთხარით ფერმერს/კურიერს მხოლოდ პროდუქციის შემოწმებისა და ჩაბარების დროს!',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderChatScreen(order: order),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: const Icon(LucideIcons.messageSquare, size: 15),
                    label: Text(
                      'ჩათი ფერმერთან',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
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
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: const Icon(LucideIcons.circleCheck, size: 15),
                    label: Text(
                      'ჩავიბარე',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (order.status == OrderStatus.pending ||
              order.canDirectlyCancel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.x, size: 15),
                label: Text(
                  'შეკვეთის გაუქმება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingStep(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.check,
            size: 12,
            color: active ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: active ? AppColors.primary : const Color(0xFFE2E8F0),
      ),
    );
  }
}

