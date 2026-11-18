import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/farmer_order_model.dart';

/// Card displaying order tracking code, date, status badge, stepper, and timer.
class OrderTrackingCard extends StatefulWidget {
  final FarmerOrder order;

  const OrderTrackingCard({super.key, required this.order});

  @override
  State<OrderTrackingCard> createState() => _OrderTrackingCardState();
}

class _OrderTrackingCardState extends State<OrderTrackingCard> {
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == OrderStatus.pending) {
      _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant OrderTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.status != OrderStatus.pending) {
      _countdownTicker?.cancel();
      _countdownTicker = null;
    } else {
      _countdownTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
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
      'დეკ',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, $hour:$minute';
  }

  Widget _buildTrackingStep(String title, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.primary : const Color(0xFFCBD5E1),
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.notoSansGeorgian(
              fontSize: 10.5,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone ? AppColors.primary : const Color(0xFFE2E8F0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final stepIndex = switch (order.status) {
      OrderStatus.pending => 1,
      OrderStatus.inProgress => 2,
      OrderStatus.completed => 3,
      OrderStatus.cancelled => 0,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.trackingNumber ?? 'AK-${order.id}',
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(order.createdAt),
                    style: GoogleFonts.notoSansGeorgian(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: order.status.badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.label,
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: order.status.color,
                  ),
                ),
              ),
            ],
          ),
          if (order.status != OrderStatus.cancelled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTrackingStep('მოლოდინში', stepIndex >= 1),
                _buildStepConnector(stepIndex >= 2),
                _buildTrackingStep('დადასტურდა', stepIndex >= 2),
                _buildStepConnector(stepIndex >= 3),
                _buildTrackingStep('ჩაბარდა', stepIndex >= 3),
              ],
            ),
            if (order.status == OrderStatus.pending &&
                order.remainingCancellationTime.inMinutes > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ფერმერის დადასტურების ვადა: ${order.formattedRemainingCancellationTime}',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (order.cancellationReason != null &&
              order.cancellationReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'გაუქმების მიზეზი: ${order.cancellationReason}',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
