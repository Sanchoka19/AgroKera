import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/otp_deck/animated_otp_card_deck.dart';
import 'reset_password_screen.dart';

/// Screen 2: SMS დადასტურება (OTP / SMS Verification Screen)
class SmsVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String? title;
  final String? subtitle;
  final FutureOr<void> Function(BuildContext context)? onVerified;

  const SmsVerificationScreen({
    super.key,
    this.email = 'ajariswyali123@gmail.com',
    this.title,
    this.subtitle,
    this.onVerified,
  });

  @override
  ConsumerState<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends ConsumerState<SmsVerificationScreen> {
  static const int _pinLength = 5;
  final GlobalKey<AnimatedOtpCardDeckState> _deckKey =
      GlobalKey<AnimatedOtpCardDeckState>();
  String _currentPin = '';

  int _secondsRemaining = 540; // 09:00 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(authStateProvider.notifier).sendEmailOtp(widget.email));
    });
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
    super.dispose();
  }

  /// Pure async verification called by the deck
  Future<bool> _verifyPin(String code) async {
    final error = await ref.read(authStateProvider.notifier).verifyEmailOtp(
          email: widget.email,
          code: code,
        );
    if (!mounted) return false;
    if (error != null) {
      AppToast.error(context, error);
      return false;
    }
    return true;
  }

  /// Success transition called after the elastic checkmark animation finishes
  Future<void> _handleSuccess() async {
    if (widget.onVerified != null) {
      await widget.onVerified!(context);
      return;
    }
    if (!mounted) return;
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
          widget.title ?? 'SMS დადასტურება',
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
                widget.subtitle ?? 'შეიყვანეთ SMS კოდი',
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

              // Animated Card Deck OTP Component
              Center(
                child: AnimatedOtpCardDeck(
                  key: _deckKey,
                  pinLength: _pinLength,
                  accentColor: AppColors.primary,
                  onVerify: _verifyPin,
                  onSuccess: _handleSuccess,
                  onPinChanged: (val) => _currentPin = val,
                ),
              ),
              const SizedBox(height: 28),

              // "არ მიგიღიათ კოდი? ახლიდან გაგზავნა"
              Center(
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _secondsRemaining = 540);
                    _startTimer();
                    await ref.read(authStateProvider.notifier).sendEmailOtp(widget.email);
                    if (!context.mounted) return;
                    AppToast.success(context, 'ახალი კოდი გაიგზავნა ${widget.email}-ზე.');
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
                onPressed: () {
                  if (_currentPin.length < _pinLength) {
                    AppToast.error(context, 'გთხოვთ სრულად შეიყვანოთ $_pinLength-ნიშნა კოდი');
                    return;
                  }
                  _deckKey.currentState?.triggerVerification(_currentPin);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
