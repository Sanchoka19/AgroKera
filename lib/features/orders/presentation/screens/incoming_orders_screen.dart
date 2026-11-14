import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';
import '../widgets/empty_orders_view.dart';
import '../widgets/farmer_order_card.dart';

/// Incoming Orders Screen for Farmers ("შემოსული შეკვეთები")
class IncomingOrdersScreen extends ConsumerStatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  ConsumerState<IncomingOrdersScreen> createState() =>
      _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends ConsumerState<IncomingOrdersScreen> {
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
    final ordersNotifier = ref.read(farmerOrdersProvider.notifier);
    final filteredOrders = ordersState.filteredOrders;

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
          'შემოსული შეკვეთები',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  _buildFilterChip(
                    key: const ValueKey('chip_all'),
                    label: 'ყველა',
                    count: ordersState.countForStatus(null),
                    isSelected: ordersState.selectedFilter == null,
                    onTap: () => ordersNotifier.setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: const ValueKey('chip_pending'),
                    label: OrderStatus.pending.label,
                    count: ordersState.countForStatus(OrderStatus.pending),
                    isSelected: ordersState.selectedFilter == OrderStatus.pending,
                    onTap: () => ordersNotifier.setFilter(OrderStatus.pending),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: const ValueKey('chip_inProgress'),
                    label: OrderStatus.inProgress.label,
                    count: ordersState.countForStatus(OrderStatus.inProgress),
                    isSelected: ordersState.selectedFilter == OrderStatus.inProgress,
                    onTap: () => ordersNotifier.setFilter(OrderStatus.inProgress),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: const ValueKey('chip_completed'),
                    label: OrderStatus.completed.label,
                    count: ordersState.countForStatus(OrderStatus.completed),
                    isSelected: ordersState.selectedFilter == OrderStatus.completed,
                    onTap: () => ordersNotifier.setFilter(OrderStatus.completed),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: const ValueKey('chip_cancelled'),
                    label: OrderStatus.cancelled.label,
                    count: ordersState.countForStatus(OrderStatus.cancelled),
                    isSelected: ordersState.selectedFilter == OrderStatus.cancelled,
                    onTap: () => ordersNotifier.setFilter(OrderStatus.cancelled),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ordersNotifier.refreshFromBackend(),
        child: filteredOrders.isEmpty
            ? EmptyOrdersView(
                filter: ordersState.selectedFilter,
                onResetFilter: () => ordersNotifier.setFilter(null),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                itemCount: filteredOrders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return FarmerOrderCard(
                    key: ValueKey('farmer_order_${order.id}'),
                    order: order,
                    onAccept: () {
                      ordersNotifier.acceptOrder(order.id);
                      AppToast.success(
                        context,
                        'შეკვეთა #${order.id} დადასტურებულია და გადავიდა მიმდინარეში!',
                      );
                    },
                    onCancel: (reason) {
                      ordersNotifier.cancelOrder(order.id, reason: reason);
                      AppToast.info(
                        context,
                        'შეკვეთა #${order.id} გაუქმებულია ($reason)',
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFilterChip({
    Key? key,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64748B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
