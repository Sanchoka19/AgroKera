import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_filter_tab.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../domain/models/farmer_order_model.dart';
import '../providers/farmer_orders_provider.dart';
import '../providers/order_chat_provider.dart';
import '../widgets/order_chat/order_chat_card_tile.dart';
import '../widgets/order_chat/order_chat_section_header.dart';
import 'order_chat_screen.dart';

/// Segmented tab for filtering chats
enum OrderChatTab { active, old, all }

/// Dedicated Screen for Order Chat Conversations ("შეკვეთის ჩათები")
/// Displays smart-ordered and grouped active and archive communication hubs
class OrderChatsListScreen extends ConsumerStatefulWidget {
  const OrderChatsListScreen({super.key});

  @override
  ConsumerState<OrderChatsListScreen> createState() =>
      _OrderChatsListScreenState();
}

class _OrderChatsListScreenState extends ConsumerState<OrderChatsListScreen> {
  OrderChatTab _selectedTab = OrderChatTab.active;
  Timer? _liveSyncTimer;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        await ref.read(farmerOrdersProvider.notifier).refreshFromBackend();
        _preloadOrderMessages();
      }),
    );

    // Live sync orders periodically
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        unawaited(ref.read(farmerOrdersProvider.notifier).refreshFromBackend());
      }
    });
  }

  void _preloadOrderMessages() {
    final auth = ref.read(authStateProvider);
    final isFarmer = auth.role == UserRole.farmer;
    final orders = isFarmer
        ? ref.read(farmerOrdersProvider).incomingOrders
        : ref.read(farmerOrdersProvider).clientOrders;

    for (final order in orders) {
      unawaited(ref.read(orderChatProvider.notifier).loadMessages(order.id));
    }
  }

  @override
  void dispose() {
    _liveSyncTimer?.cancel();
    super.dispose();
  }

  void _openChat(FarmerOrder order) {
    HapticFeedback.lightImpact();
    ref.read(orderChatReadProvider.notifier).markAsRead(order.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderChatScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isFarmer = auth.role == UserRole.farmer;
    final ordersState = ref.watch(farmerOrdersProvider);
    final chatMap = ref.watch(orderChatProvider);

    // Role-based order isolation
    final allOrders =
        isFarmer ? ordersState.incomingOrders : ordersState.clientOrders;

    final unreadOrderIds = <String>{
      for (final o in allOrders)
        if (ref.watch(isOrderChatUnreadProvider(o.id))) o.id,
    };

    // Filter into active (Pending / InProgress) and old (Completed / Cancelled)
    final unrankedActive = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.inProgress,
        )
        .toList();

    final unrankedOld = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.completed ||
              o.status == OrderStatus.cancelled,
        )
        .toList();

    // Smart Ordering via OrderChatSorter
    final sortedActiveOrders = OrderChatSorter.sortByUrgencyAndActivity(
      unrankedActive,
      chatMap,
      unreadOrderIds: unreadOrderIds,
    );
    final sortedOldOrders =
        OrderChatSorter.sortByLatestActivity(unrankedOld, chatMap);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: 'შეკვეთის ჩათები',
              showBack: true,
              showNotificationBell: false,
              showCart: false,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            ),

            // Filter Tabs Bar
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  AppFilterTab(
                    label: 'აქტიური',
                    count: sortedActiveOrders.length,
                    showZeroCount: true,
                    isSelected: _selectedTab == OrderChatTab.active,
                    onTap: () =>
                        setState(() => _selectedTab = OrderChatTab.active),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    label: 'ძველი',
                    count: sortedOldOrders.length,
                    showZeroCount: true,
                    isSelected: _selectedTab == OrderChatTab.old,
                    onTap: () => setState(() => _selectedTab = OrderChatTab.old),
                  ),
                  const SizedBox(width: 8),
                  AppFilterTab(
                    label: 'ყველა',
                    count: allOrders.length,
                    showZeroCount: true,
                    isSelected: _selectedTab == OrderChatTab.all,
                    onTap: () => setState(() => _selectedTab = OrderChatTab.all),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref
                      .read(farmerOrdersProvider.notifier)
                      .refreshFromBackend();
                  _preloadOrderMessages();
                },
                child: _buildBody(
                  activeOrders: sortedActiveOrders,
                  oldOrders: sortedOldOrders,
                  isFarmer: isFarmer,
                  chatMap: chatMap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<FarmerOrder> activeOrders,
    required List<FarmerOrder> oldOrders,
    required bool isFarmer,
    required Map<String, dynamic> chatMap,
  }) {
    final marketplace = ref.watch(marketplaceProvider);
    final auth = ref.watch(authStateProvider);

    String? resolveAvatar(FarmerOrder order) {
      final matchedFarmer = marketplace.farmers.where((f) =>
          (order.farmerId != null && f.id == order.farmerId) ||
          (order.farmerName != null &&
              (f.farmName == order.farmerName ||
                  f.farmerName == order.farmerName))).firstOrNull;
      return order.resolvePartnerAvatar(
        isFarmer: isFarmer,
        fallbackFarmerAvatar: matchedFarmer?.avatarUrl,
        fallbackCustomerAvatar:
            (auth.userId == order.clientId) ? auth.userAvatarUrl : null,
      );
    }

    switch (_selectedTab) {
      case OrderChatTab.active:
        if (activeOrders.isEmpty) {
          return _buildScrollableEmptyState(
            title: 'აქტიური ჩათები არ არის',
            subtitle:
                'შეკვეთის მიღების ან გაფორმების შემდეგ აქ გამოჩნდება აქტიური ჩატი დეტალების დასაზუსტებლად.',
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          itemCount: activeOrders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            final messages = ref.watch(orderChatProvider)[order.id];
            final lastMessage =
                (messages != null && messages.isNotEmpty) ? messages.last : null;
            return OrderChatCardTile(
              order: order,
              lastMessage: lastMessage,
              isFarmer: isFarmer,
              hasUnread: ref.watch(isOrderChatUnreadProvider(order.id)),
              avatarUrl: resolveAvatar(order),
              onTap: () => _openChat(order),
            );
          },
        );

      case OrderChatTab.old:
        if (oldOrders.isEmpty) {
          return _buildScrollableEmptyState(
            title: 'არქივი ცარიელია',
            subtitle:
                'დასრულებული და გაუქმებული შეკვეთების მიმოწერები შეინახება არქივში.',
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          itemCount: oldOrders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = oldOrders[index];
            final messages = ref.watch(orderChatProvider)[order.id];
            final lastMessage =
                (messages != null && messages.isNotEmpty) ? messages.last : null;
            return OrderChatCardTile(
              order: order,
              lastMessage: lastMessage,
              isFarmer: isFarmer,
              hasUnread: false,
              avatarUrl: resolveAvatar(order),
              onTap: () => _openChat(order),
            );
          },
        );

      case OrderChatTab.all:
        if (activeOrders.isEmpty && oldOrders.isEmpty) {
          return _buildScrollableEmptyState(
            title: 'ჩათები არ მოიძებნა',
            subtitle:
                'შეკვეთის გაფორმების შემდეგ აქ გამოჩნდება პირდაპირი ჩატი მხარეებს შორის.',
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          children: [
            // Active Section
            if (activeOrders.isNotEmpty) ...[
              OrderChatSectionHeader(
                icon: LucideIcons.messageSquare,
                title: 'აქტიური მიმოწერები',
                count: activeOrders.length,
                iconColor: AppColors.primary,
                badgeBg: AppColors.primary.withValues(alpha: 0.1),
                badgeTextColor: AppColors.primary,
              ),
              ...activeOrders.map((order) {
                final messages = ref.watch(orderChatProvider)[order.id];
                final lastMessage =
                    (messages != null && messages.isNotEmpty)
                        ? messages.last
                        : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderChatCardTile(
                    order: order,
                    lastMessage: lastMessage,
                    isFarmer: isFarmer,
                    hasUnread: ref.watch(isOrderChatUnreadProvider(order.id)),
                    avatarUrl: resolveAvatar(order),
                    onTap: () => _openChat(order),
                  ),
                );
              }),
            ],

            // Archive Section
            if (oldOrders.isNotEmpty) ...[
              OrderChatSectionHeader(
                icon: LucideIcons.archive,
                title: 'არქივი / დასრულებული',
                count: oldOrders.length,
                iconColor: const Color(0xFF64748B),
                badgeBg: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF64748B),
              ),
              ...oldOrders.map((order) {
                final messages = ref.watch(orderChatProvider)[order.id];
                final lastMessage =
                    (messages != null && messages.isNotEmpty)
                        ? messages.last
                        : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderChatCardTile(
                    order: order,
                    lastMessage: lastMessage,
                    isFarmer: isFarmer,
                    hasUnread: false,
                    avatarUrl: resolveAvatar(order),
                    onTap: () => _openChat(order),
                  ),
                );
              }),
            ],
          ],
        );
    }
  }

  Widget _buildScrollableEmptyState({
    required String title,
    required String subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
            minWidth: constraints.maxWidth,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppAssets.emptyChats,
                    width: 190,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
