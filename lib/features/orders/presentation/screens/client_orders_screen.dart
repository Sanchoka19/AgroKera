import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_reason_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';

/// Client Orders History & Live Shipment Tracking Screen ("ჩემი შეკვეთები")
class ClientOrdersScreen extends ConsumerStatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  ConsumerState<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends ConsumerState<ClientOrdersScreen> {
  bool _showActiveOnly = false;
  Timer? _liveSyncTimer;

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
              Text(
                'სულ: ₾${order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          if (order.status == OrderStatus.inProgress) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(farmerOrdersProvider.notifier)
                      .completeOrder(order.id);
                  AppToast.success(
                    context,
                    'შეკვეთა #${order.id} დადასტურებულია როგორც ჩაბარებული!',
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.circleCheck, size: 16),
                label: Text(
                  'შეკვეთის ჩაბარების დადასტურება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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

