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
import '../../../../core/widgets/app_toast.dart';
import '../widgets/forgot_password_sheet.dart';
import '../widgets/google_sign_in_sheet.dart';
import 'auth_success_splash_screen.dart';
import 'register_screen.dart';
import 'sms_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      AppToast.error(context, 'გთხოვთ შეიყვანოთ ელექტრონული ფოსტა');
      return;
    }
    if (!email.contains('@') && email.length < 9) {
      AppToast.error(context, 'გთხოვთ შეიყვანოთ სწორი ელ-ფოსტა ან ნომერი');
      return;
    }
    if (password.isEmpty || password.length < 4) {
      AppToast.error(context, 'გთხოვთ შეიყვანოთ პაროლი (მინიმუმ 4 სიმბოლო)');
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(authStateProvider.notifier).signInWithPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    AuthSuccessSplashScreen.navigate(context, message: 'ავტორიზაცია წარმატებულია');
  }

  Future<void> _onGoogleSignIn() async {
    final account = await GoogleSignInSheet.show(context);
    if (account == null || !mounted) return;

    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmsVerificationScreen(
          email: account.email,
          autoSendOnOpen: false,
          title: 'Gmail ავტორიზაცია',
          subtitle: 'შეიყვანეთ ${account.email}-ზე მოსული 5-ნიშნა კოდი',
          onVerified: (ctx) async {
            ref.read(authStateProvider.notifier).login(
              name: account.name,
              email: account.email,
              phone: account.phone,
              isGoogleAuth: true,
              role: UserRole.customer,
            );
            AuthSuccessSplashScreen.navigate(ctx, message: 'მოგესალმებით, ${account.name}');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.16, 0.32],
            colors: [
              Color(0xFF062824), // Dark Pine / Deep Midnight Teal
              Color(0xFF0D3F3B), // Rich Deep Teal
              Color(0xFF0F766E), // Brand Deep Emerald Teal
            ],
          ),
        ),
        child: Column(
          children: [
            // ==========================================
            // 1. TOP BRANDING HERO (Dark Midnight Teal Gradient)
            // ==========================================
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), // Generous 28px gap to white container!
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back button on top-left
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 26),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // AgroKera Official White Logo & Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppAssets.logoWhite,
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AGROKERA',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2DD4BF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ORGANIC MARKETPLACE OS',
                            style: GoogleFonts.notoSansGeorgian(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // 2. BOTTOM WHITE SHEET CARD (Ultra-clean modern form, zero-scroll by default)
            // ==========================================
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                'სისტემაში შესვლა',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Subtitle
                              Text(
                                'მოგესალმებით! გაიარეთ ავტორიზაცია აგროკერაზე წვდომისთვის',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Field 1: Email
                              Text(
                                'ელექტრონული ფოსტა',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'user@example.ge',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                                    prefixIcon: Icon(LucideIcons.mail, color: Color(0xFF94A3B8), size: 19),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Field 2: Password
                              Text(
                                'პაროლი',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                                    prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF94A3B8), size: 19),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                        color: const Color(0xFF94A3B8),
                                        size: 19,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => ForgotPasswordSheet.show(context),
                                  child: Text(
                                    'დაგავიწყდათ პაროლი?',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Main Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _onSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'სისტემაში შესვლა',
                                          style: AppTypography.button.copyWith(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Google Sign-In Button
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: _onGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        AppAssets.google,
                                        width: 19,
                                        height: 19,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Google-ით შესვლა',
                                        style: AppTypography.button.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Don't have an account link
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'არ გაქვთ ანგარიში? ',
                                      style: GoogleFonts.notoSansGeorgian(
                                        fontSize: 13.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'რეგისტრაცია',
                                          style: GoogleFonts.notoSansGeorgian(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Security Footer
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    'შესვლით თქვენ ეთანხმებით წესებსა და კონფიდენციალურობას',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 11.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: Text(
                                    'AGROKERA FIELD SECURITY • V1.0',
                                    style: GoogleFonts.notoSansGeorgian(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
