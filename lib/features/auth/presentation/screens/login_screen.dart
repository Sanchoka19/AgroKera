import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/forgot_password_sheet.dart';
import '../widgets/google_sign_in_sheet.dart';
import 'register_screen.dart';

/// Screen 1: ავტორიზაცია (Login / Sign In Screen)
/// Evolution:
/// - Soft brand green tint background (AppColors.primaryLight #EBF7EF)
/// - Prominent enlarged brand logo (28x28) and title ("აგროკერა" 20px bold) on top left
/// - Illustration shifted to the right, submerged ~30% behind the overlapping white card
/// - Zero-scroll viewport architecture: fits 100% on screen without scrolling
/// - Pill inputs, custom checkbox, green CTA, Google button & guest link
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

  Future<void> _onGoogleSignIn() async {
    final account = await GoogleSignInSheet.show(context);
    if (account == null || !mounted) return;

    HapticFeedback.lightImpact();
    ref.read(authStateProvider.notifier).login(
      name: account.name,
      email: account.email,
      role: UserRole.customer,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('მოგესალმებით, ${account.name}!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 60;

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ==========================================
            // 1. PINNED FIXED TOP BAR (Never scrolls or disappears)
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
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
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          LucideIcons.chevronLeft,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Brand Logo & Split-Colored Title matching Main Screen
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppAssets.logoGreen,
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'აგრო',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'კერა',
                              style: GoogleFonts.notoSansGeorgian(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==========================================
            // 2. COLLAPSIBLE ILLUSTRATION HEADER
            // Smoothly collapses when keyboard is open to yield space to the form
            // ==========================================
            AnimatedCrossFade(
              firstChild: SizedBox(
                height: 105,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 2,
                      bottom: -30,
                      child: SizedBox(
                        width: 205,
                        height: 165,
                        child: SvgPicture.asset(
                          AppAssets.signIn,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox(height: 6, width: double.infinity),
              crossFadeState: isKeyboardOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),

            // ==========================================
            // 3. OVERLAPPING WHITE SHEET CARD
            // ==========================================
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
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sheet Title & Subtitle
                              Text(
                                'ავტორიზაცია',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'მოგესალმებით! შეიყვანეთ თქვენი მონაცემები',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Email Input Field
                              _buildPillTextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                hintText: 'ელ.ფოსტა',
                                prefixIcon: LucideIcons.mail,
                              ),
                              const SizedBox(height: 10),

                              // Password Input Field
                              _buildPillTextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                hintText: 'პაროლი',
                                prefixIcon: LucideIcons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                    size: 19,
                                    color: const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),

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
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 19,
                                            height: 19,
                                            decoration: BoxDecoration(
                                              color: _rememberMe
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: _rememberMe
                                                    ? AppColors.primary
                                                    : const Color(0xFFCBD5E1),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: _rememberMe
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 13,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 7),
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
                              const SizedBox(height: 14),

                              // Primary "შესვლა" CTA Button
                              PrimaryButton(
                                text: 'შესვლა',
                                borderRadius: BorderRadius.circular(14),
                                height: 48,
                                onPressed: _onSignIn,
                              ),
                              // Secondary elements (Hidden when keyboard is active to eliminate scrolling)
                              if (!isKeyboardOpen) ...[
                                const SizedBox(height: 12),

                                // "ან გააგრძელე" Divider
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'ან გააგრძელე',
                                        style: AppTypography.caption.copyWith(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Google OAuth Button
                                InkWell(
                                  onTap: _onGoogleSignIn,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          AppAssets.google,
                                          width: 19,
                                          height: 19,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Google',
                                          style: AppTypography.button.copyWith(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),

                                // Bottom prompt: "არ გაქვთ ანგარიში? შექმენით"
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
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
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'შექმენით',
                                            style: AppTypography.bodyMedium.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

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
                                const SizedBox(height: 4),
                              ],
                            ],
                          ),
                        ),
                      ),
          ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
          prefixIcon: Icon(prefixIcon, size: 19, color: const Color(0xFF94A3B8)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}
