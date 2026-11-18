import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';
import '../widgets/client_order/client_order_card.dart';

/// Client Orders History & Live Shipment Tracking Screen ("ჩემი შეკვეთები")
class ClientOrdersScreen extends ConsumerStatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  ConsumerState<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

enum ClientOrderTab { all, active, completed, cancelled }

class _ClientOrdersScreenState extends ConsumerState<ClientOrdersScreen> {
  ClientOrderTab _selectedTab = ClientOrderTab.all;
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

  Widget _buildSectionHeader(OrderStatus status, int count) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.inProgress:
        icon = LucideIcons.truck;
        color = const Color(0xFF2563EB);
        label = 'აქტიური შეკვეთები';
        break;
      case OrderStatus.completed:
        icon = LucideIcons.checkCheck;
        color = const Color(0xFF16A34A);
        label = 'დასრულებული შეკვეთები';
        break;
      case OrderStatus.cancelled:
        icon = LucideIcons.archive;
        color = const Color(0xFF64748B);
        label = 'გაუქმებული შეკვეთები';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameGroup(OrderStatus a, OrderStatus b) {
    final aActive =
        a == OrderStatus.pending || a == OrderStatus.inProgress;
    final bActive =
        b == OrderStatus.pending || b == OrderStatus.inProgress;
    if (aActive && bActive) return true;
    return a == b;
  }

  int _countForGroup(List<FarmerOrder> orders, OrderStatus status) {
    if (status == OrderStatus.pending || status == OrderStatus.inProgress) {
      return orders
          .where((o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.inProgress)
          .length;
    }
    return orders.where((o) => o.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(farmerOrdersProvider);
    final allOrders = ordersState.sortedClientOrders;
    final activeOrders = allOrders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.inProgress)
        .toList();
    final completedOrders = allOrders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final cancelledOrders = allOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .toList();

    final orders = switch (_selectedTab) {
      ClientOrderTab.all => allOrders,
      ClientOrderTab.active => activeOrders,
      ClientOrderTab.completed => completedOrders,
      ClientOrderTab.cancelled => cancelledOrders,
    };

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

            // Horizontally Scrollable Filter Chips (Zero Overflow)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  _buildTabButton(
                    label: 'ყველა',
                    count: allOrders.length,
                    isSelected: _selectedTab == ClientOrderTab.all,
                    onTap: () =>
                        setState(() => _selectedTab = ClientOrderTab.all),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'მიმდინარე',
                    count: activeOrders.length,
                    isSelected: _selectedTab == ClientOrderTab.active,
                    onTap: () =>
                        setState(() => _selectedTab = ClientOrderTab.active),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'დასრულებული',
                    count: completedOrders.length,
                    isSelected: _selectedTab == ClientOrderTab.completed,
                    onTap: () =>
                        setState(() => _selectedTab = ClientOrderTab.completed),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'გაუქმებული',
                    count: cancelledOrders.length,
                    isSelected: _selectedTab == ClientOrderTab.cancelled,
                    onTap: () =>
                        setState(() => _selectedTab = ClientOrderTab.cancelled),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(farmerOrdersProvider.notifier)
                    .refreshFromBackend(),
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
                        // ignore: deprecated_member_use
                        cacheExtent: 2000.0,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final showSectionHeader =
                              _selectedTab == ClientOrderTab.all &&
                                  (index == 0 ||
                                      !_isSameGroup(
                                        orders[index - 1].status,
                                        order.status,
                                      ));

                          final card = ClientOrderCard(order: order);

                          if (showSectionHeader) {
                            final groupCount =
                                _countForGroup(allOrders, order.status);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(order.status, groupCount),
                                card,
                              ],
                            );
                          }

                          return card;
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
