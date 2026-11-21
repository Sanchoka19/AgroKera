import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/profile/presentation/providers/farmer_payout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_toast.dart';
import 'primary_button.dart';

/// Centralized Bank Account Guard function.
/// If farmer has configured payout IBAN, executes [onAccountPresent].
/// Otherwise, presents the [BankAccountRequiredBottomSheet].
void requireBankAccount(
  BuildContext context, {
  required WidgetRef ref,
  required VoidCallback onAccountPresent,
}) {
  final payoutState = ref.read(farmerPayoutProvider);
  if (payoutState.hasPayoutAccount) {
    onAccountPresent();
  } else {
    BankAccountRequiredBottomSheet.show(context, onSaved: onAccountPresent);
  }
}

/// Dynamic Bank Account Bottom Sheet modal:
/// Used both as a just-in-time guard on incoming order confirmation
/// and as the profile's dedicated payout details editor.
class BankAccountRequiredBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSaved;

  const BankAccountRequiredBottomSheet({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BankAccountRequiredBottomSheet(onSaved: onSaved),
      ),
    );
  }

  @override
  ConsumerState<BankAccountRequiredBottomSheet> createState() =>
      _BankAccountRequiredBottomSheetState();
}

class _BankAccountRequiredBottomSheetState
    extends ConsumerState<BankAccountRequiredBottomSheet> {
  final _ibanController = TextEditingController();
  final _beneficiaryController = TextEditingController();
  String _selectedBank = 'თიბისი ბანკი';
  bool _isSaving = false;

  static const List<String> _bankOptions = [
    'თიბისი ბანკი',
    'საქართველოს ბანკი',
    'ლიბერთი ბანკი',
    'ბაზისბანკი',
    'ტერაბანკი',
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(farmerPayoutProvider);
    if (current.iban.isNotEmpty) {
      _ibanController.text = current.iban;
    }
    if (current.bank.isNotEmpty) {
      _selectedBank = current.bank;
    }
    if (current.beneficiary.isNotEmpty) {
      _beneficiaryController.text = current.beneficiary;
    }
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim().replaceAll(' ', '').toUpperCase() ?? '';
      if (text.isNotEmpty) {
        setState(() {
          _ibanController.text = text;
        });
        if (mounted) {
          AppToast.info(context, 'IBAN ჩასმულია');
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final cleanIban =
        _ibanController.text.trim().replaceAll(' ', '').toUpperCase();
    if (cleanIban.isEmpty) {
      AppToast.warning(context, 'გთხოვთ შეიყვანოთ IBAN ანგარიშის ნომერი');
      return;
    }
    if (cleanIban.length < 15 || !cleanIban.startsWith('GE')) {
      AppToast.warning(
        context,
        'გთხოვთ შეიყვანოთ სწორი ქართული IBAN (მაგ: GE00TB...)',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(farmerPayoutProvider.notifier).savePayoutDetails(
            bank: _selectedBank,
            iban: cleanIban,
            beneficiary: _beneficiaryController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(context, 'საბანკო რეკვიზიტები შენახულია');
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'მონაცემების შენახვა ვერ მოხერხდა');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = ref.watch(farmerPayoutProvider).hasPayoutAccount;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.creditCard,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hasExisting ? 'საბანკო რეკვიზიტები' : 'საბანკო ანგარიში',
                      style: AppTypography.h1.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
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
            Text(
              hasExisting
                  ? 'გაყიდვებიდან მიღებული თანხა ჩაგერიცხებათ ამ ანგარიშზე. ნებისმიერ დროს შეგიძლიათ რეკვიზიტის განახლება.'
                  : 'შეკვეთის დასადასტურებლად და თანხის უსაფრთხოდ ჩასარიცხად მიუთითეთ თქვენი საბანკო ანგარიში (IBAN).',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ბენეფიციარი ბანკი',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown, size: 18),
                  items: _bankOptions.map((bank) {
                    return DropdownMenuItem(
                      value: bank,
                      child: Text(
                        bank,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedBank = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IBAN ანგარიშის ნომერი',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: _pasteFromClipboard,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.clipboardPaste,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ჩასმა',
                          style: GoogleFonts.notoSansGeorgian(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ibanController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'GE00TB0000000000000000',
                hintStyle: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'მიმღების სახელი / კომპანია (არასავალდებულო)',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _beneficiaryController,
              decoration: InputDecoration(
                hintText: 'მაგ: გიორგი ბერიძე',
                hintStyle: GoogleFonts.notoSansGeorgian(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: _isSaving
                  ? 'ინახება...'
                  : (hasExisting ? 'შენახვა' : 'შენახვა და დადასტურება'),
              onPressed: _isSaving ? null : _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
