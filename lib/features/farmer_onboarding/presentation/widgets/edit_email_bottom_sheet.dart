import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/core/widgets/primary_button.dart';
import '../providers/farmer_onboarding_provider.dart';

/// Bottom sheet modal enabling instant in-place email correction during onboarding.
/// Updates the email in auth & onboarding state, resets countdown, and resends OTP.
Future<void> showEditEmailBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  List<TextEditingController>? pinControllers,
}) async {
  HapticFeedback.lightImpact();
  final currentEmail =
      ref.read(farmerOnboardingProvider.notifier).resolveVerificationEmail();
  final controller = TextEditingController(text: currentEmail);
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.mail,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ელ-ფოსტის შეცვლა',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'შეიყვანეთ სწორი ელ-ფოსტის მისამართი. 5-ნიშნა ვერიფიკაციის კოდი ავტომატურად გაიგზავნება ამ მისამართზე.',
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Email input field
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.notoSansGeorgian(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'ელ-ფოსტა *',
                  hintText: 'name@example.ge',
                  prefixIcon: const Icon(
                    LucideIcons.atSign,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'გთხოვთ შეიყვანოთ ელ-ფოსტის მისამართი';
                  }
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'შეიყვანეთ სწორი ელ-ფოსტა (მაგ: user@gmail.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                text: 'შენახვა და კოდის გაგზავნა',
                height: 50,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(
                  LucideIcons.send,
                  size: 16,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final newEmail = controller.text.trim();
                    Navigator.of(ctx).pop();
                    if (pinControllers != null) {
                      for (final c in pinControllers) {
                        c.clear();
                      }
                    }
                    final sent = await ref
                        .read(farmerOnboardingProvider.notifier)
                        .updateEmailAndResend(newEmail);
                    if (context.mounted) {
                      if (sent) {
                        AppToast.success(
                          context,
                          'ახალი კოდი გაიგზავნა: $newEmail',
                          icon: LucideIcons.mailCheck,
                        );
                      } else {
                        AppToast.success(
                          context,
                          'ელ-ფოსტა შეიცვალა: $newEmail',
                          icon: LucideIcons.check,
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

