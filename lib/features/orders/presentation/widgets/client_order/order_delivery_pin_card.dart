import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/widgets/app_toast.dart';

/// Hero Card showing the secret delivery PIN required upon receiving the goods.
class OrderDeliveryPinCard extends StatelessWidget {
  final String deliveryPin;

  const OrderDeliveryPinCard({
    super.key,
    required this.deliveryPin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Key Icon and Copy Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(
                        LucideIcons.keyRound,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ჩაბარების PIN კოდი',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: deliveryPin));
                  AppToast.success(context, 'PIN კოდი დაკოპირდა!');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.copy,
                        size: 12,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'კოპირება',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Big Bold PIN Code Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Center(
              child: Text(
                deliveryPin,
                style: GoogleFonts.firaCode(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                  letterSpacing: 6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Contextual explanatory note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 13,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ეს კოდი აჩვენეთ ან გაუგზავნეთ ფერმერს პროდუქციის ჩაბარებისას შეკვეთის დასასრულებლად',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    color: const Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
