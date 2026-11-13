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

/// Screen: რეგისტრაცია (Universal Quick Sign Up Screen)
/// Follows Figma aesthetic & progressive onboarding:
/// - Header with chevron back button & centered "რეგისტრაცია"
/// - Official SignIn.svg illustration
/// - Full Name, Email, Phone, and Password input fields
/// - "რეგისტრაცია" primary CTA button -> proceeds to Role Selection
/// - "ან გააგრძელე" divider & Google 1-click Sign-Up
/// - "უკვე გაქვთ ანგარიში? შესვლა" bottom prompt
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Register basic credentials in state, then guide to role selection
    ref.read(authStateProvider.notifier).register(
      role: UserRole.customer,
      name: name.isNotEmpty ? name : 'მომხმარებელი',
      email: email.isNotEmpty ? email : 'example@gmail.com',
      phone: phone.isNotEmpty ? phone : '+995 599 00 00 00',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
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
          'რეგისტრაცია',
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
                  height: 130,
                  child: SvgPicture.asset(
                    AppAssets.signIn,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildInputLabel('სრული სახელი', isRequired: true),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: _buildInputDecoration(hint: 'გიორგი ბერიძე'),
              ),
              const SizedBox(height: 16),

              // Email
              _buildInputLabel('ელ.ფოსტა', isRequired: true),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: _buildInputDecoration(hint: 'example@gmail.com'),
              ),
              const SizedBox(height: 16),

              // Phone number
              _buildInputLabel('ტელეფონის ნომერი', isRequired: false),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: _buildInputDecoration(hint: '+995 599 12 34 56'),
              ),
              const SizedBox(height: 16),

              // Password
              _buildInputLabel('პაროლი', isRequired: true),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: _buildInputDecoration(
                  hint: '********',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                      color: const Color(0xFF334155),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Primary "რეგისტრაცია" CTA button
              PrimaryButton(
                text: 'რეგისტრაცია',
                borderRadius: BorderRadius.circular(12),
                height: 52,
                onPressed: _onSignUp,
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
                onTap: _onSignUp,
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
              const SizedBox(height: 32),

              // Bottom prompt: "უკვე გაქვთ ანგარიში? შესვლა"
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String title, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: '$title ',
        style: AppTypography.titleMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
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
    );
  }
}
