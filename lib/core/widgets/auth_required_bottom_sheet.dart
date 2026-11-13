import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../auth/auth_state_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

/// Centralized Auth Guard function.
/// If user is authenticated, executes [onAuthenticated].
/// Otherwise, presents the [AuthRequiredBottomSheet].
void requireAuth(
  BuildContext context, {
  WidgetRef? ref,
  required VoidCallback onAuthenticated,
}) {
  bool isAuthed = false;
  if (ref != null) {
    isAuthed = ref.read(authStateProvider).isAuthenticated;
  } else {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      isAuthed = container.read(authStateProvider).isAuthenticated;
    } catch (_) {
      isAuthed = false;
    }
  }

  if (isAuthed) {
    onAuthenticated();
  } else {
    AuthRequiredBottomSheet.show(context);
  }
}

/// Centralized Auth Prompt Bottom Sheet adhering to Figma screenshots:
/// - Blurred/dimmed background
/// - Top row with bold "ავტორიზაცია" title and rounded 'X' close button
/// - Explanatory subtitle
/// - Full-width Primary CTA button (#53B175)
/// - Bottom text link "არ გაქვს ანგარიში? რეგისტრაცია"
class AuthRequiredBottomSheet extends ConsumerWidget {
  const AuthRequiredBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: const AuthRequiredBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ავტორიზაცია',
                style: AppTypography.h1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subtitle description
          Text(
            'აპლიკაციის ფუნქციონალით სრულყოფილად სარგებლობისთვის გაიარე რეგისტრაცია',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Primary CTA Button
          PrimaryButton(
            text: 'ავტორიზაცია',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Bottom prompt link
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: RichText(
                text: TextSpan(
                  text: 'არ გაქვს ანგარიში? ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'რეგისტრაცია',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
