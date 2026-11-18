import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/models/farmer_order_model.dart';
import '../../../domain/models/order_message_model.dart';
import '../../controllers/order_chat_actions_controller.dart';
import '../../providers/farmer_orders_provider.dart';
import '../order_pin_verification_bottom_sheet.dart';
import 'order_chat_pin_dialog.dart';

/// Renders structured card-like chat bubbles for specific message types
/// (PIN code, PIN request, Bank details, Address, GPS, Intercom, Summary) without emojis.
class OrderChatCardBubble extends ConsumerWidget {
  final OrderMessage message;
  final bool isMe;
  final FarmerOrder? order;
  final bool isFarmer;

  const OrderChatCardBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.order,
    this.isFarmer = false,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.info(context, '$label დაკოპირდა');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    final (
      IconData icon,
      Color accentColor,
      Color bgColor,
      Color borderColor,
      String cardTitle,
      String bodyText,
      String copyLabel,
    ) = _resolveCardDetails(message);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 15, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cardTitle,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == OrderMessageType.pin)
                    _buildPinDisplay(context, ref, bodyText)
                  else
                    Text(
                      bodyText,
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),

                  // If this is a PIN request, display the interactive 1-tap transfer button
                  if (message.type == OrderMessageType.pinRequest)
                    _buildPinRequestAction(context, ref),

                  const SizedBox(height: 10),

                  // Bottom Action Strip (Copy Button + Time)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _copyToClipboard(
                          context,
                          _extractCleanText(bodyText),
                          copyLabel,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.copy,
                                size: 12,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'კოპირება',
                                style: GoogleFonts.notoSansGeorgian(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
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
    );
  }

  Widget _buildPinDisplay(BuildContext context, WidgetRef ref, String rawText) {
    final pin = _extractCleanText(rawText);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              pin,
              style: GoogleFonts.firaCode(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ),
        // If the viewer is the Farmer: Provide 1-Tap Complete Order button!
        if (isFarmer && order != null && order!.status != OrderStatus.completed) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await OrderPinVerificationBottomSheet.show(
                  context: context,
                  order: order!,
                );
                if (confirmed && context.mounted) {
                  AppToast.success(
                    context,
                    'შეკვეთა #${order!.id} წარმატებით დასრულდა!',
                  );
                  final error = await ref
                      .read(farmerOrdersProvider.notifier)
                      .completeOrder(order!.id);
                  if (error != null && context.mounted) {
                    AppToast.error(context, error);
                  }
                }
              },
              icon: const Icon(LucideIcons.checkCheck, size: 15),
              label: Text(
                'შეკვეთის დასრულება',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinRequestAction(BuildContext context, WidgetRef ref) {
    if (isFarmer) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.clock, size: 13, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'მოთხოვნა გაგზავნილია. ელოდებით PIN კოდს.',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (order == null) return const SizedBox.shrink();

    // Customer receives PIN request -> 1-Tap Transfer Button
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => OrderChatPinDialog(
              pin: order!.deliveryPin,
              onConfirm: () {
                ref.read(orderChatActionsControllerProvider).sendDeliveryPin(
                      context: context,
                      order: order!,
                    );
              },
            ),
          );
        },
        icon: const Icon(LucideIcons.keyRound, size: 15),
        label: Text(
          'PIN კოდის გადაცემა (1-Tap)',
          style: GoogleFonts.notoSansGeorgian(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  String _extractCleanText(String text) {
    if (text.contains(':\n')) {
      return text.split(':\n').last.trim();
    }
    if (text.contains(': ')) {
      return text.split(': ').last.trim();
    }
    return text.trim();
  }

  (IconData, Color, Color, Color, String, String, String) _resolveCardDetails(
    OrderMessage msg,
  ) {
    switch (msg.type) {
      case OrderMessageType.pinRequest:
        return (
          LucideIcons.shieldCheck,
          const Color(0xFF1D4ED8),
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          'PIN კოდის მოთხოვნა',
          msg.text,
          'მოთხოვნა',
        );
      case OrderMessageType.pin:
        return (
          LucideIcons.keyRound,
          const Color(0xFFB45309),
          const Color(0xFFFEF3C7),
          const Color(0xFFFDE68A),
          'ჩაბარების PIN კოდი',
          msg.text,
          'PIN კოდი',
        );
      case OrderMessageType.bankDetails:
        return (
          LucideIcons.creditCard,
          const Color(0xFF0F766E),
          const Color(0xFFCCFBF1),
          const Color(0xFF99F6E4),
          'საბანკო რეკვიზიტები',
          msg.text,
          'საბანკო რეკვიზიტები',
        );
      case OrderMessageType.address:
        return (
          LucideIcons.mapPin,
          const Color(0xFF0369A1),
          const Color(0xFFE0F2FE),
          const Color(0xFFBAE6FD),
          'მიწოდების მისამართი',
          msg.text,
          'მისამართი',
        );
      case OrderMessageType.location:
        return (
          LucideIcons.navigation,
          const Color(0xFF1D4ED8),
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          'მიმდინარე GPS ლოკაცია',
          msg.text,
          'ლოკაციის ბმული',
        );
      case OrderMessageType.intercom:
        return (
          LucideIcons.doorOpen,
          const Color(0xFF6D28D9),
          const Color(0xFFF3E8FF),
          const Color(0xFFDDD6FE),
          'სადარბაზო / დომოფონი',
          msg.text,
          'კოდი',
        );
      case OrderMessageType.summary:
        return (
          LucideIcons.receiptText,
          const Color(0xFF15803D),
          const Color(0xFFF0FDF4),
          const Color(0xFFBBF7D0),
          'შეკვეთის დეტალები',
          msg.text,
          'შეკვეთის შეჯამება',
        );
      case OrderMessageType.text:
        return (
          LucideIcons.messageSquare,
          AppColors.primary,
          const Color(0xFFF1F5F9),
          const Color(0xFFE2E8F0),
          'შეტყობინება',
          msg.text,
          'შეტყობინება',
        );
    }
  }
}
