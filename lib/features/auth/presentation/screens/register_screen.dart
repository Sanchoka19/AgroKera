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
import 'login_screen.dart';
import 'role_selection_screen.dart';

/// Screen: რეგისტრაცია (Sign-Up Screen)
/// Matching Parcel-style unified architecture:
/// - Warm organic header background (#FAF5ED) with illustration and back button
/// - Overlapping curved white card container (top radius 28px) with subtle elevation
/// - 3 Essential pill-shaped input fields with icons (#F8FAFC): Full Name, Email, Password
/// - Primary green CTA button (#53B175)
/// - "ან გააგრძელეთ" divider & Google 1-Click Sign-Up button
/// - "უკვე გაქვთ ანგარიში? შესვლა" link & guest quick access link
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    ref.read(authStateProvider.notifier).register(
      role: UserRole.customer,
      name: name.isNotEmpty ? name : 'მომხმარებელი',
      email: email.isNotEmpty ? email : 'example@gmail.com',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
    );
  }

  void _onGoogleSignUp() {
    HapticFeedback.lightImpact();
    ref.read(authStateProvider.notifier).register(
      role: UserRole.customer,
      name: 'Google მომხმარებელი',
      email: 'user@gmail.com',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
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
                      // Warm Header Section with Back Button & Brand Badge
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
                        padding: const EdgeInsets.only(top: 4, bottom: 18),
                        child: SizedBox(
                          height: 120,
                          child: SvgPicture.asset(
                            AppAssets.requireSignIn,
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
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sheet Title & Subtitle
                              Text(
                                'რეგისტრაცია',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'შექმენით ანგარიში და დაიწყეთ ნატურალური პროდუქტების შეძენა',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Full Name Field
                              _buildPillTextField(
                                controller: _nameController,
                                hintText: 'სრული სახელი (მაგ. გიორგი ბერიძე)',
                                prefixIcon: LucideIcons.user,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 12),

                              // Email Field
                              _buildPillTextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                hintText: 'ელ.ფოსტა (მაგ. example@gmail.com)',
                                prefixIcon: LucideIcons.mail,
                              ),
                              const SizedBox(height: 12),

                              // Password Field
                              _buildPillTextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                hintText: 'პაროლი (მინიმუმ 6 სიმბოლო)',
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
                              const SizedBox(height: 20),

                              // Primary "რეგისტრაცია" CTA Button
                              PrimaryButton(
                                text: 'რეგისტრაცია',
                                borderRadius: BorderRadius.circular(16),
                                height: 52,
                                onPressed: _onSignUp,
                              ),
                              const SizedBox(height: 18),

                              // "ან გააგრძელეთ" Divider
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'ან გააგრძელეთ',
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
                              const SizedBox(height: 16),

                              // Google 1-Click Fast Sign-Up Button
                              InkWell(
                                onTap: _onGoogleSignUp,
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
                                        'Google-ით რეგისტრაცია',
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
                              const SizedBox(height: 22),

                              // Bottom prompt: "უკვე გაქვთ ანგარიში? შესვლა"
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'უკვე გაქვთ ანგარიში? ',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: const Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'შესვლა',
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
                              const SizedBox(height: 14),

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
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        textCapitalization: textCapitalization,
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
