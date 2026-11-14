import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';

class GoogleAccount {
  final String name;
  final String email;
  final String initials;
  final Color avatarBg;

  const GoogleAccount({
    required this.name,
    required this.email,
    required this.initials,
    required this.avatarBg,
  });
}

/// Real Gmail-verified Google Authentication bottom sheet:
/// 1. Requires the user to enter their real Gmail address and full name
/// 2. Sends a live 5-digit verification code to that Gmail via backend SMTP
/// 3. Verifies the 5-digit code before returning the authenticated GoogleAccount
class GoogleSignInSheet extends ConsumerStatefulWidget {
  final ValueChanged<GoogleAccount> onAccountSelected;

  const GoogleSignInSheet({
    super.key,
    required this.onAccountSelected,
  });

  static Future<GoogleAccount?> show(BuildContext context) {
    return showModalBottomSheet<GoogleAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: GoogleSignInSheet(
          onAccountSelected: (account) {
            Navigator.of(ctx).pop(account);
          },
        ),
      ),
    );
  }

  @override
  ConsumerState<GoogleSignInSheet> createState() => _GoogleSignInSheetState();
}

class _GoogleSignInSheetState extends ConsumerState<GoogleSignInSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (name.isEmpty) {
      setState(() => _errorText = 'გთხოვთ შეიყვანოთ თქვენი სახელი და გვარი');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorText = 'გთხოვთ შეიყვანოთ სწორი Gmail მისამართი');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    final sent = await ref.read(authStateProvider.notifier).sendEmailOtp(email);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!sent) {
      setState(() => _errorText = 'კოდის გაგზავნა ვერ მოხერხდა, სცადეთ თავიდან');
      return;
    }

    setState(() => _codeSent = true);
    AppToast.success(context, '5-ნიშნა კოდი გაიგზავნა: $email');
  }

  Future<void> _handleVerifyCode() async {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final code = _otpController.text.trim();

    if (code.length < 5) {
      setState(() => _errorText = 'გთხოვთ შეიყვანოთ მეილზე მოსული 5-ნიშნა კოდი');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    final error = await ref.read(authStateProvider.notifier).verifyEmailOtp(
          email: email,
          code: code,
        );
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    final initials = name.isNotEmpty ? name.characters.first.toUpperCase() : 'G';
    widget.onAccountSelected(
      GoogleAccount(
        name: name,
        email: email,
        initials: initials,
        avatarBg: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Google Header with official logo
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    AppAssets.google,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google / Gmail ავტორიზაცია',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _codeSent
                            ? 'შეიყვანეთ ${_emailController.text.trim()}-ზე მოსული 5-ნიშნა კოდი'
                            : 'შეიყვანეთ თქვენი Gmail და მიიღეთ დადასტურების კოდი',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (!_codeSent) ...[
              Text(
                'სრული სახელი *',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'მაგ: საბა ევგენიძე',
                  prefixIcon: const Icon(LucideIcons.user, size: 18, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gmail მისამართი *',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(LucideIcons.mail, size: 18, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ] else ...[
              Text(
                '5-ნიშნა ვერიფიკაციის კოდი *',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '•••••',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _errorText = null;
                          }),
                  child: const Text('მეილის შეცვლა'),
                ),
              ),
            ],

            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 18),
            PrimaryButton(
              text: _codeSent ? 'კოდის დადასტურება' : 'კოდის გაგზავნა Gmail-ზე',
              height: 48,
              isLoading: _isLoading,
              borderRadius: BorderRadius.circular(14),
              onPressed: _codeSent ? _handleVerifyCode : _handleSendCode,
            ),
          ],
        ),
      ),
    );
  }
}
