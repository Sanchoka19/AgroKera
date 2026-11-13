import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/forgot_password_sheet.dart';
import 'register_screen.dart';

/// Screen 1: ავტორიზაცია (Login / Sign In Screen)
/// Parcel-style architecture:
/// - Warm organic header background (#FAF5ED) with illustration and back button
/// - Overlapping curved white card container (top radius 28px) with subtle elevation
/// - Modern pill-shaped input fields with icons (#F8FAFC)
/// - "დამიმახსოვრე" custom checkbox & "დაგავიწყდა პაროლი?" link
/// - Primary green CTA button (#53B175)
/// - "ან გააგრძელე" divider & Google OAuth pill button
/// - Navigation to RegisterScreen & "მარკეტის დათვალიერება სტუმრად →" guest link
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'example@gmail.com');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    HapticFeedback.lightImpact();
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
    const warmHeaderBg = Color(0xFFFAF5ED);

    return Scaffold(
      backgroundColor: warmHeaderBg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Warm Header Section with Back Button & Illustration
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Circular back button
                            Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 1,
                              shadowColor: Colors.black.withValues(alpha: 0.08),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(context).pop(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(
                                    LucideIcons.chevronLeft,
                                    color: AppColors.textPrimary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            // Brand badge
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  AppAssets.logoGreen,
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'აგროკერა',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            // Spacer to balance back button
                            const SizedBox(width: 42),
                          ],
                        ),
                      ),

                      // Header Illustration
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        child: SizedBox(
                          height: 130,
                          child: SvgPicture.asset(
                            AppAssets.signIn,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // Overlapping White Sheet Card
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 18,
                                offset: Offset(0, -4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sheet Title & Subtitle
                              Text(
                                'ავტორიზაცია',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'მოგესალმებით! შეიყვანეთ თქვენი მონაცემები',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Email Input Field
                              _buildPillTextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                hintText: 'ელ.ფოსტა',
                                prefixIcon: LucideIcons.mail,
                              ),
                              const SizedBox(height: 14),

                              // Password Input Field
                              _buildPillTextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                hintText: 'პაროლი',
                                prefixIcon: LucideIcons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                    size: 20,
                                    color: const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),

                              // "დამიმახსოვრე" & "დაგავიწყდა პაროლი?" Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Custom Remember Me checkbox
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _rememberMe = !_rememberMe);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: _rememberMe
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _rememberMe
                                                    ? AppColors.primary
                                                    : const Color(0xFFCBD5E1),
                                                width: 1.6,
                                              ),
                                            ),
                                            child: _rememberMe
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'დამიმახსოვრე',
                                            style: AppTypography.bodyMedium.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // "დაგავიწყდა პაროლი?" Link
                                  GestureDetector(
                                    onTap: () {
                                      ForgotPasswordSheet.show(
                                        context,
                                        initialEmail: _emailController.text.trim(),
                                      );
                                    },
                                    child: Text(
                                      'დაგავიწყდა პაროლი?',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Primary "შესვლა" CTA Button
                              PrimaryButton(
                                text: 'შესვლა',
                                borderRadius: BorderRadius.circular(16),
                                height: 52,
                                onPressed: _onSignIn,
                              ),
                              const SizedBox(height: 20),

                              // "ან გააგრძელე" Divider
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'ან გააგრძელე',
                                      style: AppTypography.caption.copyWith(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Google OAuth Button
                              InkWell(
                                onTap: _onSignIn,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        AppAssets.google,
                                        width: 20,
                                        height: 20,
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
                              const SizedBox(height: 24),

                              // Bottom prompt: "არ გაქვთ ანგარიში? შექმენით"
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
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
                              const SizedBox(height: 16),

                              // Guest shortcut: "მარკეტის დათვალიერება სტუმრად →"
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'მარკეტის დათვალიერება სტუმრად →',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF94A3B8)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
      ),
    );
  }
}
