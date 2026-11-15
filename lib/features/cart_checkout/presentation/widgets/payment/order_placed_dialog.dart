import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/payment_method_model.dart';

/// Modal dialog presented after placing an order.
/// Automatically adapts between Escrow Bank Transfer, Cash on Delivery, or Card.
class OrderPlacedDialog extends StatelessWidget {
  final String orderId;
  final double totalAmount;
  final PaymentMethodType paymentMethod;
  final AgroKeraEscrowDetails escrowDetails;
  final bool isPickup;
  final String location;
  final VoidCallback onDismiss;
  final VoidCallback? onViewOrders;
  final VoidCallback? onOpenChat;

  const OrderPlacedDialog({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.escrowDetails,
    required this.isPickup,
    required this.location,
    required this.onDismiss,
    this.onViewOrders,
    this.onOpenChat,
  });

  static void show(
    BuildContext context, {
    required String orderId,
    required double totalAmount,
    required PaymentMethodType paymentMethod,
    required AgroKeraEscrowDetails escrowDetails,
    required bool isPickup,
    required String location,
    required VoidCallback onDismiss,
    VoidCallback? onViewOrders,
    VoidCallback? onOpenChat,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderPlacedDialog(
        orderId: orderId,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        escrowDetails: escrowDetails,
        isPickup: isPickup,
        location: location,
        onDismiss: onDismiss,
        onViewOrders: onViewOrders,
        onOpenChat: onOpenChat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingCode = 'AK-$orderId';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon Pill
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCheck,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'შეკვეთის მოთხოვნა გაიგზავნა!',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              // Tracking Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'შეკვეთის კოდი: $trackingCode',
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Payment Instructions
              if (paymentMethod == PaymentMethodType.bankTransfer) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 18,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ფერმერის დადასტურების მოლოდინში',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'მოთხოვნა გაეგზავნა ფერმერს. როგორც კი ფერმერი დაადასტურებს მოსავლის მზადყოფნას, მოგივათ შეტყობინება და თანხას (${totalAmount.toStringAsFixed(0)} ₾) გადარიცხავთ AgroKera Escrow-ს დაცულ ანგარიშზე.',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12,
                          color: const Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Escrow explanation banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'წინასწარ თანხა არ იჭრება! რეკვიზიტები გადასარიცხად გააქტიურდება „ჩემი შეკვეთების“ გვერდზე.',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            color: const Color(0xFF334155),
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  isPickup
                      ? 'მოთხოვნა გადაეცა მეურნეობას ($location).\nფერმერის დადასტურების შემდეგ თანხას (${totalAmount.toStringAsFixed(0)} ₾) გადაიხდით ნაღდი ფულით ადგილზე გატანისას.'
                      : 'მოთხოვნა გადაეცა ფერმერს.\nფერმერის დადასტურების შემდეგ თანხას (${totalAmount.toStringAsFixed(0)} ₾) გადაიხდით ნაღდი ფულით კურიერთან ჩაბარებისას.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Action buttons: "ჩათი ფერმერთან", "ჩემი შეკვეთების ნახვა" & "მთავარზე დაბრუნება"
              if (onOpenChat != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onOpenChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD), width: 1.3),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.messageSquare, size: 18),
                    label: Text(
                      'ჩათი ფერმერთან',
                      style: GoogleFonts.notoSansGeorgian(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (onViewOrders != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onViewOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.packageCheck, size: 18, color: Colors.white),
                    label: Text(
                      'ჩემი შეკვეთების ნახვა',
                      style: GoogleFonts.notoSansGeorgian(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'მთავარზე დაბრუნება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'მთავარზე დაბრუნება',
                      style: GoogleFonts.notoSansGeorgian(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
