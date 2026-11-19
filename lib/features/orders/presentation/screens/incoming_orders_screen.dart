import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/widgets/app_filter_tab.dart';
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
  late final PageController _pageController;

  static const List<OrderStatus?> _filterTabs = [
    null,
    OrderStatus.pending,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    final initialFilter = ref.read(farmerOrdersProvider).selectedFilter;
    final initialIndex = _filterTabs.indexOf(initialFilter);
    _pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
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
    _pageController.dispose();
    _liveSyncTimer?.cancel();
    super.dispose();
  }

  void _onFilterSelected(int index, FarmerOrdersNotifier ordersNotifier) {
    HapticFeedback.lightImpact();
    ordersNotifier.setFilter(_filterTabs[index]);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildSectionHeader(OrderStatus status, int count) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        icon = LucideIcons.bellRing;
        color = const Color(0xFFD97706);
        label = 'საჭიროებს რეაგირებას';
        break;
      case OrderStatus.inProgress:
        icon = LucideIcons.truck;
        color = const Color(0xFF2563EB);
        label = 'აქტიური / მიმდინარე';
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

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(farmerOrdersProvider);
    final ordersNotifier = ref.read(farmerOrdersProvider.notifier);

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
                  AppFilterTab(
                    key: const ValueKey('chip_all'),
                    label: 'ყველა',
                    count: ordersState.countForStatus(null),
                    showZeroCount: true,
                    isSelected: ordersState.selectedFilter == null,
                    onTap: () => _onFilterSelected(0, ordersNotifier),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    key: const ValueKey('chip_pending'),
                    label: OrderStatus.pending.label,
                    count: ordersState.countForStatus(OrderStatus.pending),
                    showZeroCount: true,
                    isSelected: ordersState.selectedFilter == OrderStatus.pending,
                    onTap: () => _onFilterSelected(1, ordersNotifier),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    key: const ValueKey('chip_inProgress'),
                    label: OrderStatus.inProgress.label,
                    count: ordersState.countForStatus(OrderStatus.inProgress),
                    showZeroCount: true,
                    isSelected: ordersState.selectedFilter == OrderStatus.inProgress,
                    onTap: () => _onFilterSelected(2, ordersNotifier),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    key: const ValueKey('chip_completed'),
                    label: OrderStatus.completed.label,
                    count: ordersState.countForStatus(OrderStatus.completed),
                    showZeroCount: true,
                    isSelected: ordersState.selectedFilter == OrderStatus.completed,
                    onTap: () => _onFilterSelected(3, ordersNotifier),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    key: const ValueKey('chip_cancelled'),
                    label: OrderStatus.cancelled.label,
                    count: ordersState.countForStatus(OrderStatus.cancelled),
                    showZeroCount: true,
                    isSelected: ordersState.selectedFilter == OrderStatus.cancelled,
                    onTap: () => _onFilterSelected(4, ordersNotifier),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _filterTabs.length,
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
          ordersNotifier.setFilter(_filterTabs[index]);
        },
        itemBuilder: (context, index) {
          final filter = _filterTabs[index];
          final list = ordersState.ordersForFilter(filter);

          return RefreshIndicator(
            onRefresh: () => ordersNotifier.refreshFromBackend(),
            child: list.isEmpty
                ? EmptyOrdersView(
                    filter: filter,
                    onResetFilter: () => _onFilterSelected(0, ordersNotifier),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = list[index];
                      final isUpdating = ordersState.isOrderUpdating(order.id);
                      final showSectionHeader = filter == null &&
                          (index == 0 ||
                              list[index - 1].status != order.status);

                      final card = FarmerOrderCard(
                        key: ValueKey('farmer_order_${order.id}'),
                        order: order,
                        isUpdating: isUpdating,
                        onAccept: () async {
                          AppToast.success(
                            context,
                            'შეკვეთა #${order.id} დადასტურებულია და გადავიდა მიმდინარეში!',
                          );
                          final error =
                              await ordersNotifier.acceptOrder(order.id);
                          if (error != null && context.mounted) {
                            AppToast.error(context, error);
                          }
                        },
                        onCancel: (reason) {
                          ordersNotifier.cancelOrder(order.id, reason: reason);
                          AppToast.info(
                            context,
                            'შეკვეთა #${order.id} გაუქმებულია ($reason)',
                          );
                        },
                      );

                      if (showSectionHeader) {
                        final sectionCount =
                            ordersState.countForStatus(order.status);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(order.status, sectionCount),
                            card,
                          ],
                        );
                      }

                      return card;
                    },
                  ),
          );
        },
      ),
    );
  }
}
