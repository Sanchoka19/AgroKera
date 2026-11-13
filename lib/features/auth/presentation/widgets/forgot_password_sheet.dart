import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../screens/sms_verification_screen.dart';

/// Modal bottom sheet for Password Recovery:
/// - Prompts user to input or confirm their registered email
/// - Validates input and routes to SmsVerificationScreen
class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail = '',
  });

  static Future<void> show(BuildContext context, {String initialEmail = ''}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ForgotPasswordSheet(initialEmail: initialEmail),
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendCode() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'გთხოვთ შეიყვანოთ სწორი ელ.ფოსტა';
      });
      return;
    }

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmsVerificationScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row with title & close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'პაროლის აღდგენა',
                  style: AppTypography.h1.copyWith(
                    fontSize: 20,
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
            const SizedBox(height: 12),

            // Instructions
            Text(
              'შეიყვანეთ თქვენი რეგისტრირებული ელ.ფოსტა ერთჯერადი დამადასტურებელი კოდის მისაღებად',
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF64748B),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

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
              autofocus: true,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'example@gmail.com',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                errorText: _errorMessage,
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: 24),

            // Primary CTA Button
            PrimaryButton(
              text: 'კოდის გაგზავნა',
              borderRadius: BorderRadius.circular(12),
              height: 52,
              onPressed: _onSendCode,
            ),
          ],
        ),
      ),
    );
  }
}
