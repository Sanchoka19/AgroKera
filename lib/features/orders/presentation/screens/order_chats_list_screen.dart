import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/models/farmer_order_model.dart';
import '../../domain/models/order_message_model.dart';
import '../providers/farmer_orders_provider.dart';
import '../providers/order_chat_provider.dart';
import 'order_chat_screen.dart';

/// Segmented tab for filtering chats
enum OrderChatTab { all, active, old }

/// Dedicated Screen for Order Chat Conversations ("შეკვეთის ჩათები")
/// Displays active and past order communication hubs
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
      'დეკ'
    ];
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return '$h:$min';
    }
    final m = months[dt.month - 1];
    return '${dt.day} $m, $h:$min';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isFarmer = auth.role == UserRole.farmer;
    final ordersState = ref.watch(farmerOrdersProvider);

    // For farmer: incoming customer orders; For regular user: client orders
    final allOrders =
        isFarmer ? ordersState.incomingOrders : ordersState.clientOrders;

    final activeOrders = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.inProgress,
        )
        .toList();

    final oldOrders = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.completed ||
              o.status == OrderStatus.cancelled,
        )
        .toList();

    final displayedOrders = switch (_selectedTab) {
      OrderChatTab.all => allOrders,
      OrderChatTab.active => activeOrders,
      OrderChatTab.old => oldOrders,
    };

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

            // Horizontally Scrollable Tab Filter Bar (Zero Overflow)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  _buildTabButton(
                    label: 'აქტიური',
                    badgeCount: activeOrders.length,
                    isSelected: _selectedTab == OrderChatTab.active,
                    onTap: () =>
                        setState(() => _selectedTab = OrderChatTab.active),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'ძველი',
                    badgeCount: oldOrders.length,
                    isSelected: _selectedTab == OrderChatTab.old,
                    onTap: () => setState(() => _selectedTab = OrderChatTab.old),
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'ყველა',
                    badgeCount: allOrders.length,
                    isSelected: _selectedTab == OrderChatTab.all,
                    onTap: () => setState(() => _selectedTab = OrderChatTab.all),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Orders Chat List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref
                      .read(farmerOrdersProvider.notifier)
                      .refreshFromBackend();
                  _preloadOrderMessages();
                },
                child: displayedOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                        itemCount: displayedOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = displayedOrders[index];
                          return _buildChatCard(order, isFarmer);
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
    required int badgeCount,
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
          mainAxisAlignment: MainAxisAlignment.center,
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
                '$badgeCount',
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

  Widget _buildChatCard(FarmerOrder order, bool isFarmer) {
    final chatMap = ref.watch(orderChatProvider);
    final messages = chatMap[order.id];
    final OrderMessage? lastMessage =
        (messages != null && messages.isNotEmpty) ? messages.last : null;

    final isActive =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.inProgress;

    // Display title
    final titleText = isFarmer
        ? order.customerName
        : (order.contactPerson.isNotEmpty &&
                order.contactPerson != 'მყიდველი'
            ? order.contactPerson
            : 'შეკვეთა #${_shortId(order.id)}');

    final displayTime = _formatDate(lastMessage?.createdAt ?? order.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderChatScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : const Color(0xFFE2E8F0),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with active pulse indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isFarmer ? LucideIcons.user : LucideIcons.store,
                      size: 22,
                      color: isActive
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Chat Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Title & Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayTime,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Products summary & total
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${order.productsSummary} • ${order.totalAmount.toStringAsFixed(1)} ₾',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Last message preview & Status pill
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.messageSquare,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lastMessage != null
                                ? (lastMessage.isSystem
                                    ? 'სისტემა: ${lastMessage.text}'
                                    : '${lastMessage.senderName}: ${lastMessage.text}')
                                : 'დააჭირეთ ჩათის გასახსნელად...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 12.5,
                              fontWeight: lastMessage != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: lastMessage != null
                                  ? const Color(0xFF334155)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: order.status.badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.label,
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: order.status.color,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.messageSquareQuote,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedTab == OrderChatTab.active
                  ? 'აქტიური ჩათები არ არის'
                  : 'ჩათები არ მოიძებნა',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'შეკვეთის გაფორმების შემდეგ აქ გამოჩნდება პირდაპირი ჩატი ფერმერთან დეტალების დასაზუსტებლად.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
