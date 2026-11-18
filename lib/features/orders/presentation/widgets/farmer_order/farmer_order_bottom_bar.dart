import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Ergonomic, modular bottom action bar for farmer order processing
class FarmerOrderBottomBar extends StatelessWidget {
  final FarmerOrder order;
  final bool isUpdating;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onOpenChat;

  const FarmerOrderBottomBar({
    super.key,
    required this.order,
    required this.isUpdating,
    required this.onAccept,
    required this.onComplete,
    required this.onCancel,
    required this.onOpenChat,
  });

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Completed or Cancelled State
    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: OutlinedButton.icon(
            onPressed: onOpenChat,
            icon: const Icon(LucideIcons.messageSquare, size: 17),
            label: Text(
              'ჩათის ისტორია',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
    }

    // 2. In Progress State
    if (order.status == OrderStatus.inProgress) {
      final canDirectCancel = order.canDirectlyCancel;
      final remainingTime = order.remainingCancellationTime;
      final cancelLabel = canDirectCancel
          ? 'გაუქმება (${_formatCountdown(remainingTime)})'
          : 'გაუქმების მოთხოვნა';

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary Completion Button
              ElevatedButton.icon(
                onPressed: isUpdating ? null : onComplete,
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.checkCheck, size: 18),
                label: Text(
                  'შეკვეთის დასრულება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary actions: Cancel & Chat
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(LucideIcons.ban, size: 15),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cancelLabel,
                          maxLines: 1,
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFFECACA),
                          width: 1.2,
                        ),
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenChat,
                      icon: const Icon(LucideIcons.messageSquare, size: 15),
                      label: Text(
                        'ჩათი',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        minimumSize: const Size.fromHeight(42),
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

    // 3. Pending State
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(LucideIcons.x, size: 16),
                label: Text(
                  'უარყოფა',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(
                    color: Color(0xFFFECACA),
                    width: 1.2,
                  ),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : onAccept,
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.check, size: 18),
                label: Text(
                  'შეკვეთის მიღება',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

