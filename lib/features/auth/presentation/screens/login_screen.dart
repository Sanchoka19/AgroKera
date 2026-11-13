import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import 'role_selection_screen.dart';
import 'sms_verification_screen.dart';

/// Screen 1: ავტორიზაცია (Login / Sign In Screen)
/// Matching Figma screenshot:
/// - Header with chevron back icon & centered "ავტორიზაცია"
/// - Official SignIn.svg illustration
/// - Email & Password inputs with toggleable visibility & required asterisks
/// - "დაგავიწყდა პაროლი?" right-aligned link leading to SMS Verification
/// - Primary "შესვლა" CTA button (#53B175)
/// - "ან გააგრძელე" divider
/// - Google OAuth button with official Google SVG
/// - Bottom "არ გაქვთ ანგარიში? შექმენით" prompt leading to Role Selection
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'example@gmail.com');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    ref.read(authStateProvider.notifier).login(
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : 'example@gmail.com',
      role: UserRole.customer,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('წარმატებით გაიარეთ ავტორიზაცია!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ავტორიზაცია',
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration
              Center(
                child: SizedBox(
                  height: 150,
                  child: SvgPicture.asset(
                    AppAssets.signIn,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Email label & input
              RichText(
                text: TextSpan(
                  text: 'ელ.ფოსტა ',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  children: const [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password label & input
              RichText(
                text: TextSpan(
                  text: 'პაროლი ',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  children: const [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '********',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                      color: const Color(0xFF334155),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // "დაგავიწყდა პაროლი?" link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SmsVerificationScreen(
                          email: _emailController.text.trim().isNotEmpty
                              ? _emailController.text.trim()
                              : 'example@gmail.com',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'დაგავიწყდა პაროლი?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Main "შესვლა" CTA button
              PrimaryButton(
                text: 'შესვლა',
                borderRadius: BorderRadius.circular(12),
                height: 52,
                onPressed: _onSignIn,
              ),
              const SizedBox(height: 24),

              // "ან გააგრძელე" Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFCBD5E1), thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ან გააგრძელე',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFCBD5E1), thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Google OAuth Button
              InkWell(
                onTap: _onSignIn,
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppAssets.google,
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Google',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bottom prompt: "არ გაქვთ ანგარიში? შექმენით"
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'არ გაქვთ ანგარიში? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'შექმენით',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
