import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../marketplace/data/models/farmer_model.dart';

/// Card allowing user to choose between courier delivery and self-pickup.
class CheckoutDeliveryMethodCard extends StatelessWidget {
  final bool isPickup;
  final bool isCovered;
  final bool isWeightExceeded;
  final bool isHeavyOrder;
  final double totalWeight;
  final double effectiveHeavyFee;
  final String vehicleLabel;
  final MapEntry<String, double>? matchedZone;
  final FarmerModel farmer;
  final ValueChanged<bool> onPickupChanged;

  const CheckoutDeliveryMethodCard({
    super.key,
    required this.isPickup,
    required this.isCovered,
    required this.isWeightExceeded,
    required this.isHeavyOrder,
    required this.totalWeight,
    required this.effectiveHeavyFee,
    required this.vehicleLabel,
    required this.matchedZone,
    required this.farmer,
    required this.onPickupChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Text(
            'მიღების მეთოდი',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (isWeightExceeded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'წონა (${totalWeight.toStringAsFixed(1)} კგ) აჭარბებს საკურიერო მიტანის ლიმიტს (250 კგ). ხელმისაწვდომია მხოლოდ თვითგატანა მეურნეობიდან.',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isHeavyOrder) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.truck,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'მძიმე შეკვეთა (${totalWeight.toStringAsFixed(1)} კგ) • ტრანსპორტირება: $vehicleLabel (+${effectiveHeavyFee.toInt()} ₾)',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 1. Delivery Service (საკურიერო მიტანა)
          GestureDetector(
            onTap: isWeightExceeded
                ? () {
                    AppToast.warning(
                      context,
                      'წონა (${totalWeight.toStringAsFixed(1)} კგ) აჭარბებს საკურიერო მიტანის ლიმიტს (250 კგ). ხელმისაწვდომია მხოლოდ თვითგატანა.',
                    );
                  }
                : (isCovered
                    ? () => onPickupChanged(false)
                    : () {
                        AppToast.warning(
                          context,
                          'ფერმერი ამ მისამართზე მიტანას ვერ უზრუნველყოფს',
                        );
                      }),
            child: Opacity(
              opacity: (!isWeightExceeded && isCovered) ? 1.0 : 0.45,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: (!isPickup && isCovered)
                      ? AppColors.primaryLight
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (!isPickup && isCovered)
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    width: (!isPickup && isCovered) ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: (!isPickup && isCovered)
                            ? Colors.white
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.truck,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'მიტანის სერვისი',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isWeightExceeded
                                ? '>250 კგ (შეუძლებელია)'
                                : (isCovered && matchedZone != null
                                    ? '${matchedZone!.value.toInt()} ₾ • საკურიერო მიწოდება'
                                    : 'მიუწვდომელია ამ მისამართზე'),
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCovered && !isWeightExceeded
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isPickup && isCovered)
                      const Icon(
                        LucideIcons.checkCircle,
                        size: 20,
                        color: AppColors.primary,
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Self-Pickup Option (თვითგატანა)
          GestureDetector(
            onTap: () => onPickupChanged(true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isPickup
                    ? AppColors.primaryLight
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPickup
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: isPickup ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isPickup
                          ? Colors.white
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'თვითგატანა',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '0 ₾ • უფასო (მეურნეობიდან გატანა)',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPickup)
                    const Icon(
                      LucideIcons.checkCircle,
                      size: 20,
                      color: AppColors.primary,
                    )
                  else
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isPickup) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.mapPin,
                      size: 15,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'მეურნეობის ლოკაცია: ${farmer.farmName} — ${farmer.location}',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF166534),
                      ),
                    ),
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
