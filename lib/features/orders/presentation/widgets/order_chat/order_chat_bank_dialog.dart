import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';

/// Dialog allowing the farmer to review and send their bank account details / IBAN.
class OrderChatBankDialog extends StatefulWidget {
  final String initialBank;
  final String initialIban;
  final String initialBeneficiary;
  final void Function({
    required String bankName,
    required String iban,
    required String beneficiary,
  }) onSend;

  const OrderChatBankDialog({
    super.key,
    required this.initialBank,
    required this.initialIban,
    required this.initialBeneficiary,
    required this.onSend,
  });

  @override
  State<OrderChatBankDialog> createState() => _OrderChatBankDialogState();
}

class _OrderChatBankDialogState extends State<OrderChatBankDialog> {
  late final TextEditingController _ibanController;
  late final TextEditingController _beneficiaryController;
  late String _selectedBank;

  static const List<String> _banks = [
    'თიბისი ბანკი (TBC Bank)',
    'საქართველოს ბანკი (Bank of Georgia)',
    'ლიბერთი ბანკი (Liberty Bank)',
    'ბაზისბანკი (Basisbank)',
    'ტერაბანკი (Terabank)',
  ];

  @override
  void initState() {
    super.initState();
    _ibanController = TextEditingController(text: widget.initialIban);
    _beneficiaryController =
        TextEditingController(text: widget.initialBeneficiary);
    _selectedBank = _banks.contains(widget.initialBank)
        ? widget.initialBank
        : _banks.first;
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  void _submit() {
    final cleanIban = _ibanController.text.trim().replaceAll(' ', '');
    final cleanBeneficiary = _beneficiaryController.text.trim();

    if (cleanIban.isEmpty) return;

    Navigator.of(context).pop();
    widget.onSend(
      bankName: _selectedBank,
      iban: cleanIban,
      beneficiary: cleanBeneficiary.isNotEmpty
          ? cleanBeneficiary
          : widget.initialBeneficiary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(
                    LucideIcons.creditCard,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'საბანკო რეკვიზიტები',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'გადაუგზავნეთ მყიდველს ანგარიშის ნომერი',
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bank Selector
            Text(
              'ბანკი',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  icon: const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  items: _banks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(
                        bank,
                        style: GoogleFonts.notoSansGeorgian(
                          fontSize: 12.5,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Beneficiary (Recipient name)
            Text(
              'მიმღების სახელი / მეურნეობა',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _beneficiaryController,
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 13,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // IBAN input
            Text(
              'IBAN ანგარიშის ნომერი',
              style: GoogleFonts.notoSansGeorgian(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ibanController,
              style: GoogleFonts.firaCode(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'GE00TB0000000000000000',
                hintStyle: GoogleFonts.firaCode(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'გაუქმება',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(LucideIcons.sendHorizontal, size: 16),
                    label: Text(
                      'გაგზავნა',
                      style: GoogleFonts.notoSansGeorgian(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
