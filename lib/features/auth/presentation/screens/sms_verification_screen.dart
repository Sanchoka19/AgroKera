import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import 'reset_password_screen.dart';

/// Screen 2: SMS დადასტურება (OTP / SMS Verification Screen)
/// Matching Figma screenshot:
/// - AppBar with back button & "SMS დადასტურება" title
/// - Official Verification.svg illustration
/// - "შეიყვანეთ SMS კოდი" bold heading
/// - "კოდი გაიგზავნა example@gmail.com" subtle info
/// - 5-digit verification PIN input boxes
/// - "არ მიგიღიათ კოდი? ახლიდან გაგზავნა" resend prompt
/// - Active countdown clock timer (09:00)
/// - "დადასტურება" CTA button leading to Password Reset
class SmsVerificationScreen extends StatefulWidget {
  final String email;

  const SmsVerificationScreen({
    super.key,
    this.email = 'example@gmail.com',
  });

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  static const int _pinLength = 5;
  final List<TextEditingController> _controllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_pinLength, (_) => FocusNode());

  int _secondsRemaining = 540; // 09:00 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes.$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onVerify() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ResetPasswordScreen(),
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
          'SMS დადასტურება',
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
                  height: 160,
                  child: SvgPicture.asset(
                    AppAssets.verification,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'შეიყვანეთ SMS კოდი',
                style: AppTypography.h1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'კოდი გაიგზავნა ${widget.email}',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 5-digit PIN input row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_pinLength, (index) {
                  return SizedBox(
                    width: 54,
                    height: 58,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '8',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
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
                      onChanged: (value) {
                        if (value.isNotEmpty && index < _pinLength - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // "არ მიგიღიათ კოდი? ახლიდან გაგზავნა"
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _secondsRemaining = 540);
                    _startTimer();
                    AppToast.success(context, 'ახალი SMS კოდი გაიგზავნა.');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'არ მიგიღიათ კოდი? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'ახლიდან გაგზავნა',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Countdown timer row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // "დადასტურება" CTA button
              PrimaryButton(
                text: 'დადასტურება',
                borderRadius: BorderRadius.circular(12),
                height: 52,
                onPressed: _onVerify,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
