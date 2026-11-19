import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/farmer_onboarding/presentation/providers/farmer_onboarding_provider.dart';
import '../../../domain/models/farmer_order_model.dart';
import '../../controllers/order_chat_actions_controller.dart';
import 'order_chat_bank_dialog.dart';
import 'order_chat_intercom_dialog.dart';
import 'order_chat_pin_dialog.dart';

/// Modal bottom sheet showcasing role-specific structured quick actions.
/// Farmer actions: PIN code request & Bank account / IBAN sharing.
/// Customer actions: Address, GPS, Intercom, PIN code transfer & Order summary.
/// Strictly adheres to zero-emoji design guidelines with clean Lucide icons.
class OrderChatQuickActionsSheet extends ConsumerWidget {
  final FarmerOrder order;
  final bool isFarmer;

  const OrderChatQuickActionsSheet({
    super.key,
    required this.order,
    required this.isFarmer,
  });

  static Future<void> show(
    BuildContext context, {
    required FarmerOrder order,
    required bool isFarmer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => OrderChatQuickActionsSheet(
        order: order,
        isFarmer: isFarmer,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(orderChatActionsControllerProvider);
    final customerAddress = controller.resolveCustomerAddressToShare(order);
    final hasCustomerAddress =
        customerAddress != null && customerAddress.isNotEmpty;
    final isClient = !isFarmer;
    final hasPin = order.deliveryPin.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sheet Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFarmer ? 'ფერმერის მოქმედებები' : 'სწრაფი მოქმედებები',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Farmer-only menu: ONLY PIN Request & Bank details
          if (isFarmer) ...[
            // Action 1: PIN Code Request
            _buildActionTile(
              icon: LucideIcons.shieldCheck,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFEFF6FF),
              title: 'PIN კოდის მოთხოვნა',
              subtitle: 'გაუგზავნეთ მყიდველს 4-ნიშნა PIN კოდის მოთხოვნა',
              onTap: () async {
                Navigator.of(context).pop();
                await controller.requestDeliveryPin(
                  context: context,
                  order: order,
                );
              },
            ),
            const SizedBox(height: 8),

            // Action 2: Bank details / IBAN sharing
            _buildActionTile(
              icon: LucideIcons.creditCard,
              iconColor: const Color(0xFF0D9488),
              iconBg: const Color(0xFFCCFBF1),
              title: 'საბანკო რეკვიზიტების გაზიარება',
              subtitle: 'ანგარიშის ნომრისა (IBAN) და ბანკის გაგზავნა',
              onTap: () {
                Navigator.of(context).pop();
                final auth = ref.read(authStateProvider);
                String initialIban = '';
                String initialBank = 'თიბისი ბანკი (TBC Bank)';
                try {
                  final onboarding = ref.read(farmerOnboardingProvider);
                  if (onboarding.iban.isNotEmpty) {
                    initialIban = onboarding.iban;
                  }
                  if (onboarding.selectedBank.isNotEmpty) {
                    initialBank = onboarding.selectedBank;
                  }
                } catch (_) {}

                showDialog<void>(
                  context: context,
                  builder: (_) => OrderChatBankDialog(
                    initialBank: initialBank,
                    initialIban: initialIban,
                    initialBeneficiary:
                        auth.farmName ?? auth.userName ?? 'აგროკერა ფერმერი',
                    onSend: ({
                      required String bankName,
                      required String iban,
                      required String beneficiary,
                    }) {
                      controller.sendBankDetails(
                        context: context,
                        order: order,
                        bankName: bankName,
                        iban: iban,
                        beneficiaryName: beneficiary,
                      );
                    },
                  ),
                );
              },
            ),
          ] else ...[
            // Customer menu actions
            // Action 1: Delivery Address
            _buildActionTile(
              icon: LucideIcons.mapPin,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFE0F2FE),
              title: 'მისამართის გაზიარება',
              subtitle: hasCustomerAddress
                  ? customerAddress
                  : 'თქვენი მიწოდების მისამართი',
              onTap: () async {
                Navigator.of(context).pop();
                await controller.sendDeliveryAddress(
                  context: context,
                  order: order,
                );
              },
            ),
            const SizedBox(height: 8),

            // Action 2: Current GPS Location
            _buildActionTile(
              icon: LucideIcons.navigation,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFEFF6FF),
              title: 'GPS ლოკაციის გაზიარება',
              subtitle: 'მიმდინარე კოორდინატები Google Maps-ის ბმულით',
              onTap: () async {
                Navigator.of(context).pop();
                await controller.sendCurrentGpsLocation(
                  context: context,
                  order: order,
                );
              },
            ),
            const SizedBox(height: 8),

            // Action 3: Entrance / Intercom Code
            _buildActionTile(
              icon: LucideIcons.doorOpen,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFFF3E8FF),
              title: 'სადარბაზო / დომოფონის კოდი',
              subtitle: 'სადარბაზოს, შლაგბაუმის ან ჭიშკრის მონაცემები',
              onTap: () {
                Navigator.of(context).pop();
                showDialog<void>(
                  context: context,
                  builder: (_) => OrderChatIntercomDialog(
                    onSend: (code) {
                      controller.sendIntercomCode(
                        context: context,
                        order: order,
                        codeDetails: code,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Action 4: PIN Code Transfer (Only for customer)
            if (isClient && hasPin) ...[
              _buildActionTile(
                icon: LucideIcons.keyRound,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                title: 'ჩაბარების PIN კოდის გადაცემა',
                subtitle: 'გადაეცით მხოლოდ პროდუქციის მიღებისა და შემოწმებისას',
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog<void>(
                    context: context,
                    builder: (_) => OrderChatPinDialog(
                      pin: order.deliveryPin,
                      onConfirm: () {
                        controller.sendDeliveryPin(
                          context: context,
                          order: order,
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],

            // Action 5: Order Items Summary
            _buildActionTile(
              icon: LucideIcons.receiptText,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFF0FDF4),
              title: 'შეკვეთის შეჯამება',
              subtitle: 'პროდუქტების სია, რაოდენობები და ჯამური თანხა',
              onTap: () async {
                Navigator.of(context).pop();
                await controller.sendOrderSummary(
                  context: context,
                  order: order,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
