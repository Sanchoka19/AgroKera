import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/models/payment_method_model.dart';

/// Highly compact and responsive escrow bank details card.
/// Designed for pixel-perfect display without vertical/horizontal overflow.
class EscrowBankDetailsWidget extends StatelessWidget {
  final AgroKeraEscrowDetails escrow;
  final String? orderReference;
  final double? amount;

  const EscrowBankDetailsWidget({
    super.key,
    required this.escrow,
    this.orderReference,
    this.amount,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    AppToast.success(context, '$label დაკოპირდა!');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with security badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: Color(0xFF15803D),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgroKera Escrow დაცვა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF166534),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'თანხა გაიყინება შეკვეთის ჩაბარებამდე',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11,
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // IBAN Row with 1-tap copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF166534).withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'საბანკო ანგარიში (IBAN):',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        escrow.iban,
                        style: GoogleFonts.firaCode(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(context, escrow.iban, 'IBAN'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Recipient & Bank info grid (Compact)
          Row(
            children: [
              Expanded(
                child: Text(
                  'მიმღები: ${escrow.recipientName}',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ს/კ: ${escrow.identificationCode}',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (orderReference != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _copyToClipboard(
                context,
                orderReference!,
                'დანიშნულების კოდი',
              ),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'დანიშნულება: $orderReference',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 11,
                        color: const Color(0xFF166534),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.copy,
                    size: 12,
                    color: Color(0xFF166534),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
