import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/constants/app_assets.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/theme/app_typography.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../../providers/farmer_onboarding_provider.dart';
import '../edit_email_bottom_sheet.dart';

class Step5SmsVerificationWidget extends ConsumerWidget {
  final List<TextEditingController> pinControllers;
  final List<FocusNode> pinFocusNodes;

  const Step5SmsVerificationWidget({
    super.key,
    required this.pinControllers,
    required this.pinFocusNodes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(farmerOnboardingProvider);
    final email = state.customEmail?.isNotEmpty == true
        ? state.customEmail!
        : ref.watch(farmerOnboardingProvider.notifier).resolveVerificationEmail();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            height: 150,
            child: SvgPicture.asset(
              AppAssets.verification,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'შეიყვანეთ SMS კოდი',
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                'კოდი გაიგზავნა:',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                email,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => showEditEmailBottomSheet(
                  context,
                  ref,
                  pinControllers: pinControllers,
                ),
                child: Text(
                  'შეცვლა',
                  style: GoogleFonts.notoSansGeorgian(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 5 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(pinControllers.length, (index) {
            return SizedBox(
              width: 54,
              height: 58,
              child: TextField(
                controller: pinControllers[index],
                focusNode: pinFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '8',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                ),
                onChanged: (value) {
                  final fullCode =
                      pinControllers.map((c) => c.text.trim()).join();
                  ref
                      .read(farmerOnboardingProvider.notifier)
                      .setOtpCode(fullCode);

                  if (value.isNotEmpty && index < pinControllers.length - 1) {
                    pinFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    pinFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Resend prompt
        Center(
          child: GestureDetector(
            onTap: () async {
              ref.read(farmerOnboardingProvider.notifier).resetTimer(540);
              await ref.read(farmerOnboardingProvider.notifier).sendOtp();
              if (context.mounted) {
                AppToast.success(
                  context,
                  'ახალი კოდი გაიგზავნა $email-ზე.',
                );
              }
            },
            child: RichText(
              text: TextSpan(
                text: 'არ მიგიღიათ კოდი? ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(
                    text: 'ახლიდან გაგზავნა',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.clock, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              state.formattedTime,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
