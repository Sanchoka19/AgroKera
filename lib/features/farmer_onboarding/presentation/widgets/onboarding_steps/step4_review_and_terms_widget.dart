import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import '../../providers/farmer_onboarding_provider.dart';
import '../edit_email_bottom_sheet.dart';
import '../onboarding_shared_widgets.dart';

class Step4ReviewAndTermsWidget extends ConsumerWidget {
  final TextEditingController farmNameController;
  final TextEditingController ibanController;

  const Step4ReviewAndTermsWidget({
    super.key,
    required this.farmNameController,
    required this.ibanController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(farmerOnboardingProvider);
    final user = ref.watch(authStateProvider);
    final resolvedEmail = state.customEmail?.isNotEmpty == true
        ? state.customEmail!
        : ref.watch(farmerOnboardingProvider.notifier).resolveVerificationEmail();

    final cleanFarmName = farmNameController.text.trim().isNotEmpty
        ? farmNameController.text.trim()
        : (state.farmName.trim().isNotEmpty ? state.farmName.trim() : 'ოქროს ქვაფი');

    final cleanIban = ibanController.text.trim().isNotEmpty
        ? ibanController.text.trim()
        : state.iban.trim();
    final maskedIban = cleanIban.length > 7
        ? '****${cleanIban.substring(cleanIban.length - 7)}'
        : '****7ER9';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
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
                  Text(
                    'დეტალები',
                    style: AppTypography.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(farmerOnboardingProvider.notifier).setStep(1);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: const Text(
                        'შეცვლა',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OnboardingReviewRow(
                'სრული სახელი:',
                user.userName ?? 'ფერმერი',
              ),
              OnboardingReviewRow(
                'ელ-ფოსტა:',
                resolvedEmail,
                trailing: InkWell(
                  onTap: () => showEditEmailBottomSheet(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'შეცვლა',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              OnboardingReviewRow(
                'ფერმის სახელი:',
                cleanFarmName,
              ),
              OnboardingReviewRow(
                'ფერმის გარეკანი:',
                state.farmPhotoName ??
                    (state.hasFarmPhoto ? 'არჩეულია' : 'სტანდარტული'),
              ),
              OnboardingReviewRow(
                'მისამართი:',
                state.dynamicAddress.isNotEmpty
                    ? state.dynamicAddress
                    : '${state.selectedRegion}, ${state.selectedCity}, 1 რაიონი',
              ),
              OnboardingReviewRow('ბანკი:', state.selectedBank),
              OnboardingReviewRow('IBAN:', maskedIban),
              OnboardingReviewRow(
                'თვითგატანა:',
                state.isPickupEnabled ? 'აქტიურია (0 ₾)' : 'გათიშულია',
              ),
              OnboardingReviewRow(
                'ფერმერის მიტანა:',
                state.isDeliveryEnabled
                    ? '${state.deliveryCity} (${state.deliveryDays.join(', ')}) • ${state.isFreeDelivery ? "უფასო" : "${state.deliveryFee.toInt()} ₾"}'
                    : 'არ არის არჩეული',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms and conditions Card
        OnboardingSectionCard(
          title: 'წესები და პირობები',
          icon: LucideIcons.building2,
          children: [
            // Checkbox 1
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(farmerOnboardingProvider.notifier).toggleAgreeTerms();
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingCustomCheckbox(
                    value: state.agreeTerms,
                    onChanged: (val) {
                      ref
                          .read(farmerOnboardingProvider.notifier)
                          .toggleAgreeTerms();
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'ვეთანხმები agrokera-ს ',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        children: const [
                          TextSpan(
                            text: 'მომსახურების პირობებსა',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' და '),
                          TextSpan(
                            text: 'კონფიდენციალურობის პოლიტიკას',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Checkbox 2
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(farmerOnboardingProvider.notifier).toggleAgreeQuality();
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingCustomCheckbox(
                    value: state.agreeQuality,
                    onChanged: (val) {
                      ref
                          .read(farmerOnboardingProvider.notifier)
                          .toggleAgreeQuality();
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ვაცნობიერებ სრულ პასუხისმგებლობას ჩემ მიერ განთავსებული პროდუქციის ხარისხზე, უსაფრთხოებასა და ბუნებრიობაზე.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
