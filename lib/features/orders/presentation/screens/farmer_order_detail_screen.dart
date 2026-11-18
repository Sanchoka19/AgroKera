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
import '../widgets/farmer_order/farmer_order_bottom_bar.dart';
import '../widgets/farmer_order/farmer_order_customer_card.dart';
import '../widgets/farmer_order/farmer_order_financial_card.dart';
import '../widgets/farmer_order/farmer_order_items_card.dart';
import '../widgets/farmer_order/farmer_order_status_header_card.dart';
import '../widgets/order_pin_verification_bottom_sheet.dart';
import 'order_chat_screen.dart';

/// Clean, modular detailed view of an incoming farmer order.
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
    // 1-second ticker for cancellation countdown & 5-second live backend sync
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

  // ==========================================
  // BUSINESS LOGIC ACTIONS
  // ==========================================

  Future<void> _onAcceptOrder(FarmerOrder order) async {
    AppToast.success(context, 'შეკვეთა #${order.id} მიღებულია!');
    final error = await ref
        .read(farmerOrdersProvider.notifier)
        .acceptOrder(order.id);
    if (error != null && mounted) {
      AppToast.error(context, error);
    }
  }

  Future<void> _onCompleteOrder(FarmerOrder order) async {
    bool confirmed = false;

    if (order.isBankTransfer) {
      confirmed = await OrderPinVerificationBottomSheet.show(
        context: context,
        order: order,
      );
    } else {
      confirmed = await AppConfirmationBottomSheet.show(
        context: context,
        title: 'ნაღდი თანხის ჩაბარება',
        message:
            'დაადასტურეთ, რომ ნაღდი თანხა (₾${order.totalAmount.toStringAsFixed(2)}) ჩაიბარეთ და შეკვეთა #${order.id} წარმატებით გადაეცით მყიდველს.',
        confirmText: 'თანხა მივიღე და ჩავაბარე',
        cancelText: 'უკან',
        type: ConfirmationType.positive,
        icon: LucideIcons.banknote,
      );
    }

    if (confirmed && mounted) {
      AppToast.success(
        context,
        'შეკვეთა #${order.id} წარმატებით დასრულდა!',
      );
      final error = await ref
          .read(farmerOrdersProvider.notifier)
          .completeOrder(order.id);
      if (error != null && mounted) {
        AppToast.error(context, error);
      }
    }
  }

  void _onOpenChat(FarmerOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderChatScreen(order: order),
      ),
    );
  }

  Future<void> _onCancelOrder(FarmerOrder order) async {
    if (order.status == OrderStatus.inProgress && !order.canDirectlyCancel) {
      // Past direct cancellation window -> Submit cancellation request to admin
      final reason = await AppReasonBottomSheet.show(
        context: context,
        title: 'გაუქმების მოთხოვნა',
        subtitle:
            'შეკვეთა #${order.id} • მოთხოვნა გადაეგზავნება ადმინისტრაციას',
        confirmButtonText: 'მოთხოვნის გაგზავნა',
        confirmButtonColor: const Color(0xFFEA580C),
        icon: LucideIcons.send,
        reasons: AppReasonBottomSheet.defaultOrderCancellationReasons,
      );

      if (reason != null && mounted) {
        AppToast.success(
          context,
          'გაუქმების მოთხოვნა ადმინისტრაციას გადაეგზავნა',
        );
      }
      return;
    }

    // Direct Cancellation
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
      ref
          .read(farmerOrdersProvider.notifier)
          .cancelOrder(order.id, reason: reason);
      AppToast.info(context, 'შეკვეთა #${order.id} გაუქმებულია');
    }
  }

  // ==========================================
  // UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(farmerOrdersProvider);
    final order = ordersState.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => ordersState.orders.isNotEmpty
          ? ordersState.orders.first
          : throw StateError('Order not found'),
    );
    final isUpdating = ordersState.isOrderUpdating(order.id);

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
            tooltip: 'ჩათი მყიდველთან',
            onPressed: () => _onOpenChat(order),
          ),
          const SizedBox(width: 4),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Status & Assurance Header
              FarmerOrderStatusHeaderCard(order: order),
              const SizedBox(height: 12),

              // 2. Actionable: What to prepare
              FarmerOrderItemsCard(items: order.items),
              const SizedBox(height: 12),

              // 3. Customer & Delivery Information
              FarmerOrderCustomerCard(
                order: order,
                onOpenChat: () => _onOpenChat(order),
              ),
              const SizedBox(height: 12),

              // 4. Financial Breakdown
              FarmerOrderFinancialCard(order: order),
            ],
          ),
        ),
      ),

      // Docked, Ergonomic Action Bar
      bottomNavigationBar: FarmerOrderBottomBar(
        order: order,
        isUpdating: isUpdating,
        onAccept: () => _onAcceptOrder(order),
        onComplete: () => _onCompleteOrder(order),
        onCancel: () => _onCancelOrder(order),
        onOpenChat: () => _onOpenChat(order),
      ),
    );
  }
}
