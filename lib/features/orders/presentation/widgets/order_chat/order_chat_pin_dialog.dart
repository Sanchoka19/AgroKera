import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';

/// Modal dialog for confirming delivery PIN code transfer.
/// Designed for escrow security - ensures the user is aware of the consequences.
class OrderChatPinDialog extends StatelessWidget {
  final String pin;
  final VoidCallback onConfirm;

  const OrderChatPinDialog({
    super.key,
    required this.pin,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Warning Icon Container
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(
                LucideIcons.shieldAlert,
                color: Color(0xFFD97706),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            // Dialog Title
            Text(
              'ჩაბარების PIN კოდის გადაცემა',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            // Warning Notice
            Text(
              'PIN კოდის გადაცემა ადასტურებს, რომ თქვენ პროდუქცია ჩაიბარეთ და ხარისხი შეამოწმეთ. გაუგზავნეთ მხოლოდ მაშინ, როცა შეკვეთა უკვე თქვენთანაა.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // PIN Display Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.keyRound,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    pin,
                    style: GoogleFonts.firaCode(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'გაუქმება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    icon: const Icon(LucideIcons.sendHorizontal, size: 16),
                    label: Text(
                      'გაგზავნა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

