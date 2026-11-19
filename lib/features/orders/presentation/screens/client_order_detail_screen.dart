import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../../domain/models/order_message_model.dart';
import '../controllers/order_chat_actions_controller.dart';
import '../providers/farmer_orders_provider.dart';
import '../providers/order_chat_provider.dart';
import '../widgets/client_order/order_delivery_info_card.dart';
import '../widgets/client_order/order_delivery_pin_card.dart';
import '../widgets/client_order/order_escrow_payment_card.dart';
import '../widgets/client_order/order_products_breakdown_card.dart';
import '../widgets/client_order/order_tracking_card.dart';
import '../widgets/order_chat/order_chat_pin_dialog.dart';
import '../../../reviews/presentation/widgets/order_review_prompt_card.dart';
import 'order_chat_screen.dart';

/// Clean, modular client order details screen ("ჩემი შეკვეთის დეტალები")
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
  bool _isReportedLocally = false;
  bool _isPinSentLocally = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        await ref.read(farmerOrdersProvider.notifier).refreshFromBackend();
        await ref.read(orderChatProvider.notifier).loadMessages(widget.orderId);
      }),
    );
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
              OrderTrackingCard(order: order),
              const SizedBox(height: 12),
              if (order.status == OrderStatus.completed) ...[
                OrderReviewPromptCard(order: order),
                const SizedBox(height: 12),
              ],
              if (order.status == OrderStatus.inProgress &&
                  order.isBankTransfer) ...[
                OrderEscrowPaymentCard(
                  order: order,
                  isReported: isReported,
                  onReportPayment: () {
                    setState(() => _isReportedLocally = true);
                    ref
                        .read(farmerOrdersProvider.notifier)
                        .reportBankTransferSent(order.id);
                    AppToast.success(
                      context,
                      'გადარიცხვა დაფიქსირდა! სისტემა ამოწმებს თანხას.',
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (order.status == OrderStatus.inProgress) ...[
                OrderDeliveryPinCard(deliveryPin: order.deliveryPin),
                const SizedBox(height: 12),
              ],
              OrderProductsBreakdownCard(order: order),
              const SizedBox(height: 12),
              OrderDeliveryInfoCard(order: order),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(order),
    );
  }

  Widget? _buildBottomActions(FarmerOrder order) {
    if (order.status == OrderStatus.inProgress) {
      final chatMessages = ref.watch(orderChatProvider)[order.id] ?? const [];
      final hasPinInChat =
          chatMessages.any((m) => m.type == OrderMessageType.pin);
      final isPinSent = _isPinSentLocally || hasPinInChat;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => OrderChatPinDialog(
                  pin: order.deliveryPin,
                  onConfirm: () async {
                    final sent = await ref
                        .read(orderChatActionsControllerProvider)
                        .sendDeliveryPin(
                          context: context,
                          order: order,
                        );
                    if (sent && mounted) {
                      setState(() => _isPinSentLocally = true);
                      AppToast.success(
                        context,
                        'ჩაბარების PIN კოდი (${order.deliveryPin}) გაეგზავნა ფერმერს შეკვეთის დასასრულებლად!',
                      );
                    }
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isPinSent ? const Color(0xFF0F766E) : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(46),
            ),
            icon: Icon(
              isPinSent ? LucideIcons.checkCheck : LucideIcons.keyRound,
              size: 16,
            ),
            label: Text(
              isPinSent
                  ? 'PIN კოდი გაგზავნილია • ჩათში ხელახლა ჩაგდება'
                  : 'ჩავიბარე შეკვეთა • PIN კოდის გაგზავნა',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
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
                final error = await ref
                    .read(farmerOrdersProvider.notifier)
                    .cancelOrder(order.id, reason: reason);
                if (!mounted) return;
                if (error != null) {
                  AppToast.error(context, error);
                } else {
                  AppToast.info(
                    context,
                    'შეკვეთა #${order.id} გაუქმებულია ($reason)',
                  );
                }
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
