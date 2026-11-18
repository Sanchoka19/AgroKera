import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/farmer_order_model.dart';
import '../../domain/models/order_message_model.dart';
import '../controllers/order_chat_actions_controller.dart';
import '../providers/order_chat_provider.dart';
import '../widgets/order_chat/order_chat_bank_dialog.dart';
import '../widgets/order_chat/order_chat_card_bubble.dart';
import '../widgets/order_chat/order_chat_intercom_dialog.dart';
import '../widgets/order_chat/order_chat_pin_dialog.dart';
import '../widgets/order_chat/order_chat_quick_actions_sheet.dart';

/// Live Order Communication Chat Screen between Farmer & Customer
class OrderChatScreen extends ConsumerStatefulWidget {
  final FarmerOrder order;

  const OrderChatScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  Timer? _liveSyncTimer;

  @override
  void initState() {
    super.initState();
    PushNotificationService.activeChatOrderId = widget.order.id;
    unawaited(
      Future.microtask(() {
        ref.read(orderChatProvider.notifier).loadMessages(widget.order.id);
        ref.read(orderChatReadProvider.notifier).markAsRead(widget.order.id);
      }),
    );

    // Live polling for incoming messages every 2.5 seconds
    _liveSyncTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        ref.read(orderChatProvider.notifier).syncMessages(widget.order.id);
        ref.read(orderChatReadProvider.notifier).markAsRead(widget.order.id);
      }
    });
  }

  @override
  void dispose() {
    if (PushNotificationService.activeChatOrderId == widget.order.id) {
      PushNotificationService.activeChatOrderId = null;
    }
    _liveSyncTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _textController.text;
    if (text.trim().isEmpty || _isSending) return;

    final auth = ref.read(authStateProvider);
    final isOrderSeller = auth.role == UserRole.farmer &&
        (auth.farmerId == widget.order.farmerId ||
            widget.order.farmerId == null ||
            widget.order.clientId != auth.userId);

    final senderId = isOrderSeller
        ? (auth.farmerId ?? auth.userId ?? 'farmer_unknown')
        : (auth.userId ?? 'customer_unknown');
    final senderName = isOrderSeller
        ? (auth.farmName ?? auth.userName ?? 'ფერმერი')
        : (auth.userName ?? widget.order.customerName);

    setState(() => _isSending = true);
    if (quickText == null) _textController.clear();

    try {
      await ref.read(orderChatProvider.notifier).sendMessage(
            orderId: widget.order.id,
            text: text,
            senderId: senderId,
            senderRole: isOrderSeller ? UserRole.farmer : UserRole.customer,
            senderName: senderName,
          );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'ჩათი ჯერ ხელმიუწვდომელია');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allChats = ref.watch(orderChatProvider);
    final messages = allChats[widget.order.id] ?? const [];
    final auth = ref.watch(authStateProvider);
    final isOrderSeller = auth.role == UserRole.farmer &&
        (auth.farmerId == widget.order.farmerId ||
            widget.order.farmerId == null ||
            widget.order.clientId != auth.userId);
    final isFarmer = isOrderSeller;
    final isActive = widget.order.status == OrderStatus.inProgress ||
        widget.order.status == OrderStatus.pending;

    // Scroll down when new messages arrive
    ref.listen(orderChatProvider, (previous, next) {
      if ((previous?[widget.order.id]?.length ?? 0) <
          (next[widget.order.id]?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final partnerName = isOrderSeller
        ? widget.order.customerName
        : (widget.order.farmerName ?? 'ფერმერი');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.order.trackingNumber ?? 'AK-${widget.order.id}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.order.status.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.order.status.label,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: widget.order.status.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              partnerName,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (widget.order.contactPhone.trim().isNotEmpty)
            IconButton(
              icon: const Icon(
                LucideIcons.phone,
                size: 19,
                color: Color(0xFF16A34A),
              ),
              tooltip: 'ნომრის კოპირება / დარეკვა',
              onPressed: () => ref
                  .read(orderChatActionsControllerProvider)
                  .copyPhoneNumber(context, widget.order.contactPhone),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Builder(
              builder: (ctx) {
                final avatarUrl = widget.order.farmerAvatarUrl;
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE6F4EA),
                  backgroundImage: (!isFarmer &&
                          avatarUrl != null &&
                          avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (isFarmer || avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                          partnerName.isNotEmpty
                              ? partnerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Security Banner
            if (widget.order.status == OrderStatus.pending)
              _buildPendingBanner()
            else
              _buildSecurityBanner(isFarmer),

            // Messages List
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'შეტყობინებები არ არის',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final currentUserId = auth.userId;
                        final currentFarmerId = auth.farmerId;
                        final isMe = (currentUserId != null &&
                                msg.senderId == currentUserId) ||
                            (currentFarmerId != null &&
                                msg.senderId == currentFarmerId) ||
                            (isFarmer
                                ? msg.senderRole == UserRole.farmer
                                : msg.senderRole == UserRole.customer);

                        if (msg.isSystem) {
                          return _buildSystemMessage(msg);
                        }

                        if (msg.type != OrderMessageType.text) {
                          return OrderChatCardBubble(
                            message: msg,
                            isMe: isMe,
                            order: widget.order,
                            isFarmer: isFarmer,
                          );
                        }

                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
            ),

            // Quick replies and actions (only if active)
            if (isActive) _buildQuickReplies(isFarmer),

            // Input Bar
            _buildBottomBar(isActive, isFarmer),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF7ED),
      child: Row(
        children: [
          const Icon(LucideIcons.lock, size: 16, color: Color(0xFFEA580C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ჩათი გაიხსნება ფერმერის მიერ შეკვეთის დადასტურების შემდეგ',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9A3412),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner(bool isFarmer) {
    if (widget.order.isBankTransfer) {
      if (isFarmer) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFEFF6FF),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck,
                  size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ჩაბარების 4-ნიშნა PIN კოდი გამოართვით მყიდველს პირისპირ, პროდუქციის გადაცემის შემდეგ.',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFFEF3C7),
        child: Row(
          children: [
            const Icon(LucideIcons.shieldAlert,
                size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'უსაფრთხოებისთვის: თქვენი ჩაბარების PIN კოდი (${widget.order.deliveryPin}) უთხარით ფერმერს მხოლოდ პროდუქტის შემოწმებისა და ჩაბარებისას. ნუ გაუგზავნით კოდს ჩათში წინასწარ!',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cash payment banner
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF0FDF4),
      child: Row(
        children: [
          const Icon(LucideIcons.banknote,
              size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFarmer
                  ? 'ნაღდი ანგარიშსწორება: თანხა (₾${widget.order.totalAmount.toStringAsFixed(2)}) ჩაიბარეთ პირისპირ პროდუქციის გადაცემისას.'
                  : 'ნაღდი ანგარიშსწორება: თანხა (₾${widget.order.totalAmount.toStringAsFixed(2)}) გადაუხადეთ ფერმერს პირისპირ პროდუქციის ჩაბარებისას.',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(OrderMessage msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.info, size: 13, color: Color(0xFF475569)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                msg.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(OrderMessage msg, bool isMe) {
    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                msg.senderName,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              msg.text,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : const Color(0xFF0F172A),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: GoogleFonts.firaCode(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(bool isFarmer) {
    final controller = ref.read(orderChatActionsControllerProvider);
    final hasPin = widget.order.deliveryPin.trim().isNotEmpty;
    final isEscrow = widget.order.isBankTransfer;

    final standardReplies = isFarmer
        ? ['გზაში ვარ', '10 წუთში მოვალ', 'ადგილზე ვარ', 'შლაგბაუმთან ვდგავარ']
        : ['როდის შეძლებთ გამოგზავნას?', 'ადგილზე ვარ', 'ჭიშკართან გელოდებით', 'მადლობა!'];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          // Standard conversational replies
          ...standardReplies.map((reply) {
            return Container(
              margin: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(
                  reply,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _sendMessage(reply),
              ),
            );
          }),

          if (isFarmer) ...[
            // Farmer Action 1: PIN Request
            ActionChip(
              avatar: const Icon(
                LucideIcons.shieldCheck,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              label: Text(
                'PIN-ის მოთხოვნა',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              backgroundColor: const Color(0xFFEFF6FF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => controller.requestDeliveryPin(
                context: context,
                order: widget.order,
              ),
            ),
            const SizedBox(width: 8),

            // Farmer Action 2: Bank details / IBAN
            ActionChip(
              avatar: const Icon(
                LucideIcons.creditCard,
                size: 14,
                color: Color(0xFF0D9488),
              ),
              label: Text(
                'საბანკო რეკვიზიტები',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F766E),
                ),
              ),
              backgroundColor: const Color(0xFFCCFBF1),
              side: const BorderSide(color: Color(0xFF99F6E4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                final auth = ref.read(authStateProvider);
                showDialog<void>(
                  context: context,
                  builder: (_) => OrderChatBankDialog(
                    initialBank: 'თიბისი ბანკი (TBC Bank)',
                    initialIban: '',
                    initialBeneficiary:
                        auth.farmName ?? auth.userName ?? 'აგროკერა ფერმერი',
                    onSend: ({
                      required String bankName,
                      required String iban,
                      required String beneficiary,
                    }) {
                      controller.sendBankDetails(
                        context: context,
                        order: widget.order,
                        bankName: bankName,
                        iban: iban,
                        beneficiaryName: beneficiary,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ] else ...[
            // Customer Action 1: Delivery Address
            ActionChip(
              avatar: const Icon(
                LucideIcons.mapPin,
                size: 14,
                color: Color(0xFF0284C7),
              ),
              label: Text(
                'მისამართი',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0369A1),
                ),
              ),
              backgroundColor: const Color(0xFFF0F9FF),
              side: const BorderSide(color: Color(0xFFBAE6FD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => controller.sendDeliveryAddress(
                context: context,
                order: widget.order,
              ),
            ),
            const SizedBox(width: 8),

            // Customer Action 2: GPS Location
            ActionChip(
              avatar: const Icon(
                LucideIcons.navigation,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              label: Text(
                'GPS ლოკაცია',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              backgroundColor: const Color(0xFFEFF6FF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => controller.sendCurrentGpsLocation(
                context: context,
                order: widget.order,
              ),
            ),
            const SizedBox(width: 8),

            // Customer Action 3: Intercom Code
            ActionChip(
              avatar: const Icon(
                LucideIcons.doorOpen,
                size: 14,
                color: Color(0xFF7C3AED),
              ),
              label: Text(
                'სადარბაზო',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D28D9),
                ),
              ),
              backgroundColor: const Color(0xFFF5F3FF),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => OrderChatIntercomDialog(
                    onSend: (code) => controller.sendIntercomCode(
                      context: context,
                      order: widget.order,
                      codeDetails: code,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Customer Action 4: Delivery PIN (Only client & escrow)
            if (hasPin && isEscrow) ...[
              ActionChip(
                avatar: const Icon(
                  LucideIcons.keyRound,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                label: Text(
                  'PIN კოდი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
                backgroundColor: const Color(0xFFFFFBEB),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => OrderChatPinDialog(
                      pin: widget.order.deliveryPin,
                      onConfirm: () => controller.sendDeliveryPin(
                        context: context,
                        order: widget.order,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isActive, bool isFarmer) {
    if (!isActive) {
      final isCancelled = widget.order.status == OrderStatus.cancelled;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.lock, size: 15, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isCancelled
                    ? 'შეკვეთა გაუქმებულია • ჩათი დახურულია'
                    : 'შეკვეთა დასრულებულია • ჩათი დახურულია',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Quick actions '+' button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                LucideIcons.plus,
                size: 20,
                color: Color(0xFF334155),
              ),
              tooltip: 'სწრაფი მოქმედებები',
              onPressed: () => OrderChatQuickActionsSheet.show(
                context,
                order: widget.order,
                isFarmer: isFarmer,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13.5,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                hintText: 'დაწერეთ შეტყობინება...',
                hintStyle: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isSending ? null : () => _sendMessage(),
            icon: const Icon(LucideIcons.sendHorizontal, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
