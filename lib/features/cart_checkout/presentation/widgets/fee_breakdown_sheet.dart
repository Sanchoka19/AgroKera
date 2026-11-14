import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum FeeBreakdownType {
  standard,
  heavyWeight,
  heavyVolume,
  freeDelivery,
}

class FeeBreakdownSheet extends StatelessWidget {
  final double currentWeight;
  final double currentSubtotal;
  final FeeBreakdownType type;

  const FeeBreakdownSheet({
    super.key,
    this.currentWeight = 3.8,
    this.currentSubtotal = 25.50,
    this.type = FeeBreakdownType.heavyWeight,
  });

  static Future<void> show(
    BuildContext context, {
    double currentWeight = 3.8,
    double currentSubtotal = 25.50,
    FeeBreakdownType? type,
  }) {
    final determinedType = type ??
        (currentSubtotal >= 150.0
            ? FeeBreakdownType.freeDelivery
            : (currentWeight > 25.0
                ? FeeBreakdownType.heavyWeight
                : FeeBreakdownType.standard));

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FeeBreakdownSheet(
        currentWeight: currentWeight,
        currentSubtotal: currentSubtotal,
        type: determinedType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            'რა განსაზღვრავს ჩვენს\nსაფასურს',
            style: AppTypography.h1.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Standard Delivery Fee Row
          if (type != FeeBreakdownType.freeDelivery) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.truck, size: 24, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'მიტანის საფასური კარამდე',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '10.00 ₾',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Heavy Weight / Volume Fee Row
          if (type == FeeBreakdownType.heavyWeight || type == FeeBreakdownType.standard) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.package, size: 24, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'მძიმე შეკვეთის\nსაფასური',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ემატება, რადგან თქვენი შეკვეთის წონამ (${currentWeight.toStringAsFixed(1)} კგ) გადააჭარბა 25 კგ-იან ზღვარს.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '5.00 ₾',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else if (type == FeeBreakdownType.heavyVolume) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.package, size: 24, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'მძიმე შეკვეთის\nსაფასური',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ემატება, რადგან თქვენი შეკვეთის მოცულობამ (2.1 ყუთი) გადააჭარბა 2-ყუთიან ზღვარს.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '5.00 ₾',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else if (type == FeeBreakdownType.freeDelivery) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.gift, size: 24, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'გილოცავთ, თქვენ\nსარგებლობთ უფასო\nმიტანის სერვისით!',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'გილოცავთ, თქვენ სარგებლობთ უფასო მიტანით! რადგან შეკვეთის ღირებულება 150 ლარს აღემატება, ჩვენი გუნდი მას თბილისის მასშტაბით სრულიად უფასოდ მოგაწვდით.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '00.00 ₾',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // "გასაგებია" Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA668),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'გასაგებია',
                style: AppTypography.button.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

