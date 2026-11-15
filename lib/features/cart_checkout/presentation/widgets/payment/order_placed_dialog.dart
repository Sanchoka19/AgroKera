import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
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
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    AppToast.success(context, '$label დაკოპირდა!');
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
                'შეკვეთა გაფორმდა!',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 19,
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
                Text(
                  'თანხა (${totalAmount.toStringAsFixed(0)} ₾) გადმორიცხეთ AgroKera Escrow-ს ანგარიშზე:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // IBAN copy container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'IBAN:',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(
                              context,
                              escrowDetails.iban,
                              'IBAN',
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.copy,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'კოპირება',
                                  style: GoogleFonts.notoSansGeorgian(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        escrowDetails.iban,
                        style: GoogleFonts.firaCode(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'დანიშნულება: $trackingCode',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(
                              context,
                              trackingCode,
                              'დანიშნულების კოდი',
                            ),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                LucideIcons.copy,
                                size: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Escrow explanation banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'თანხა გაიყინება AgroKera-ში და ფერმერს გადაეცემა მხოლოდ შეკვეთის ჩაბარების შემდეგ.',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11,
                            color: const Color(0xFF166534),
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
                      ? 'შეკვეთა მზადდება მეურნეობაში ($location).\nთანხას (${totalAmount.toStringAsFixed(0)} ₾) გადაიხდით ნაღდი ფულით ადგილზე გატანისას.'
                      : 'შეკვეთა გადაეცა ფერმერს.\nთანხას (${totalAmount.toStringAsFixed(0)} ₾) გადაიხდით ნაღდი ფულით კურიერთან ჩაბარებისას.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Action buttons: "ჩემი შეკვეთების ნახვა" & "მთავარზე დაბრუნება"
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
