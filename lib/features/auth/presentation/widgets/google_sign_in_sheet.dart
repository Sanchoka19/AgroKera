import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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

/// Official native-styled Google Account Picker bottom sheet.
/// Provides authentic account choice, terms consent, and realistic auth state.
class GoogleSignInSheet extends StatefulWidget {
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
  State<GoogleSignInSheet> createState() => _GoogleSignInSheetState();
}

class _GoogleSignInSheetState extends State<GoogleSignInSheet> {
  bool _isAuthenticating = false;
  String? _selectedEmail;

  final List<GoogleAccount> _accounts = const [
    GoogleAccount(
      name: 'გიორგი ბერიძე',
      email: 'giorgi.beridze@gmail.com',
      initials: 'გ',
      avatarBg: Color(0xFF1E88E5), // Google Blue
    ),
    GoogleAccount(
      name: 'აგრო ფერმა',
      email: 'agro.farm.geo@gmail.com',
      initials: 'ა',
      avatarBg: AppColors.primary, // Agro Green
    ),
  ];

  Future<void> _handleAccountTap(GoogleAccount account) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedEmail = account.email;
      _isAuthenticating = true;
    });

    // Realistic authentication latency
    await Future.delayed(const Duration(milliseconds: 550));

    if (mounted) {
      widget.onAccountSelected(account);
    }
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
                      'Google-ით ავტორიზაცია',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'აირჩიეთ ანგარიში აგროკერაში გასაგრძელებლად',
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

          if (_isAuthenticating) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'მიმდინარეობს დაკავშირება...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedEmail ?? '',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Account List
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _accounts.length; i++) ...[
                    _buildAccountTile(_accounts[i]),
                    if (i < _accounts.length - 1)
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildUseAnotherAccountTile(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Terms & Privacy Disclosure
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'გასაგრძელებლად, Google გაუზიარებს თქვენს სახელს, ელფოსტასა და პროფილის სურათს აგროკერას. აპლიკაციის გამოყენება რეგულირდება კონფიდენციალურობის პოლიტიკით.',
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  height: 1.45,
                  color: const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountTile(GoogleAccount account) {
    return InkWell(
      onTap: () => _handleAccountTap(account),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: account.avatarBg,
              child: Text(
                account.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    account.email,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseAnotherAccountTile() {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _handleAccountTap(
          const GoogleAccount(
            name: 'სხვა მომხმარებელი',
            email: 'new.user@gmail.com',
            initials: '+',
            avatarBg: Color(0xFF64748B),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Icon(
                LucideIcons.userPlus,
                size: 18,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'სხვა ანგარიშის გამოყენება',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
