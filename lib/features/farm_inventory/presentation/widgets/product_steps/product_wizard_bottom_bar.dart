import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/widgets/primary_button.dart';

/// Bottom action bar for product wizard containing Back button (steps 2 & 3)
/// and Primary CTA button for Next step / Publish.
class ProductWizardBottomBar extends StatelessWidget {
  final int currentStep;
  final bool isExisting;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ProductWizardBottomBar({
    super.key,
    required this.currentStep,
    required this.isExisting,
    required this.isSaving,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          if (currentStep > 1) ...[
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  'უკან',
                  style: GoogleFonts.notoSansGeorgian(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: PrimaryButton(
              text: currentStep == 1
                  ? 'შემდეგი: ფასი და მარაგი'
                  : currentStep == 2
                      ? 'შემდეგი: გადახედვა'
                      : (isExisting
                          ? 'ცვლილებების შენახვა'
                          : 'პროდუქტის გამოქვეყნება'),
              icon: Icon(
                currentStep == 3
                    ? (isExisting ? LucideIcons.check : LucideIcons.send)
                    : LucideIcons.arrowRight,
                size: 18,
                color: Colors.white,
              ),
              height: 52,
              borderRadius: BorderRadius.circular(12),
              isLoading: isSaving,
              onPressed: isSaving ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}

