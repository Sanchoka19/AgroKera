import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';

/// Screen 3: პაროლის აღდგენა (Password Reset / Update Screen)
/// Matching Figma screenshot:
/// - AppBar with back button & "პაროლის აღდგენა" title
/// - Explanatory prompt: "თქვენი ახალი პაროლი განსხვავებული უნდა იყოს ძველი პაროლისგან"
/// - "ახალი პაროლი *" input with toggleable eye icon
/// - "გაიმეორე ახალი პაროლი *" input with toggleable eye icon
/// - "განახლება" primary CTA button
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1.isEmpty) {
      AppToast.error(context, 'გთხოვთ შეიყვანოთ ახალი პაროლი');
      return;
    }
    if (p1.length < 6) {
      AppToast.error(context, 'პაროლი უნდა შედგებოდეს მინიმუმ 6 სიმბოლოსგან');
      return;
    }
    if (p2.isEmpty) {
      AppToast.error(context, 'გთხოვთ გაიმეოროთ ახალი პაროლი');
      return;
    }
    if (p1 != p2) {
      AppToast.error(context, 'პაროლები ერთმანეთს არ ემთხვევა.');
      return;
    }

    // Success: return to login screen
    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/login');
    AppToast.success(context, 'პაროლი წარმატებით განახლდა! გაიარეთ ავტორიზაცია.');
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
          'პაროლის აღდგენა',
          style: AppTypography.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Illustration
                      Center(
                        child: SizedBox(
                          height: 140,
                          child: SvgPicture.asset(
                            AppAssets.verification,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info description
                      Text(
                        'თქვენი ახალი პაროლი განსხვავებული უნდა იყოს ძველი პაროლისგან',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Field 1: ახალი პაროლი *
                      RichText(
                        text: TextSpan(
                          text: 'ახალი პაროლი ',
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
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'შეიყვანე თქვენი პაროლი',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 20,
                              color: const Color(0xFF334155),
                            ),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
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
                      const SizedBox(height: 20),

                      // Field 2: გაიმეორე ახალი პაროლი *
                      RichText(
                        text: TextSpan(
                          text: 'გაიმეორე ახალი პაროლი ',
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
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'შეიყვანე თქვენი პაროლი',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 20,
                              color: const Color(0xFF334155),
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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

                      const Spacer(),
                      const SizedBox(height: 24),

                      // "განახლება" Primary CTA button
                      PrimaryButton(
                        text: 'განახლება',
                        borderRadius: BorderRadius.circular(12),
                        height: 52,
                        onPressed: _onUpdate,
                      ),
                      const SizedBox(height: 8),
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
}
