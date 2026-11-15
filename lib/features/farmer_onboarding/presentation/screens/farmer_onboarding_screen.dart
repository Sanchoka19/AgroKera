import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/core/widgets/primary_button.dart';
import '../models/farmer_onboarding_state.dart';
import '../providers/farmer_onboarding_provider.dart';
import '../providers/farmer_onboarding_validator.dart';
import '../widgets/onboarding_steps/step1_farm_info_widget.dart';
import '../widgets/onboarding_steps/step2_status_selection_widget.dart';
import '../widgets/onboarding_steps/step3_legal_and_bank_widget.dart';
import '../widgets/onboarding_steps/step4_delivery_widget.dart';
import '../widgets/onboarding_steps/step4_review_and_terms_widget.dart';
import '../widgets/onboarding_steps/step5_sms_verification_widget.dart';

// Re-export LegalStatus so existing references across the app remain intact
export '../models/farmer_onboarding_state.dart' show LegalStatus;

/// 6-Step Farmer Onboarding & Verification Wizard
/// Strictly adhering to Figma designs and cleanly decomposed:
/// - Step 1/6: ფერმის ინფორმაცია & მისამართი (Name, Cover Photo, Region, City, Interactive Map)
/// - Step 2/6: აირჩიე თქვენი სტატუსი (Centered large status cards)
/// - Step 3/6: იურიდიული დეტალები & საბანკო ანგარიში (ID, Documents Upload, Bank & IBAN)
/// - Step 4/6: მიწოდების პირობები & გრაფიკი (Self-Pickup, Scheduled Delivery & Day Toggle Buttons)
/// - Step 5/6: დეტალები & წესები და პირობები (Summary review with spacious "შეცვლა" + 2 Checkboxes)
/// - Step 6/6: SMS დადასტურება (5-digit OTP verification & complete onboarding)
class FarmerOnboardingScreen extends ConsumerStatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  ConsumerState<FarmerOnboardingScreen> createState() =>
      _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends ConsumerState<FarmerOnboardingScreen> {
  final _farmNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  late final FarmerOnboardingNotifier _onboardingNotifier;

  static const int _pinLength = 5;
  final List<TextEditingController> _pinControllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(_pinLength, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _onboardingNotifier = ref.read(farmerOnboardingProvider.notifier);
    final st = ref.read(farmerOnboardingProvider);
    _farmNameController.text = st.farmName;
    _idNumberController.text = st.idNumber;
    _ibanController.text = st.iban;
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _idNumberController.dispose();
    _ibanController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    _onboardingNotifier.cancelTimer();
    super.dispose();
  }

  String? _validateStep(int step, FarmerOnboardingState state) {
    switch (step) {
      case 1:
        return FarmerOnboardingValidator.validateStep1(
          farmName: state.farmName,
          hasFarmPhoto: state.hasFarmPhoto,
          region: state.selectedRegion,
          city: state.selectedCity,
        );
      case 2:
        return null;
      case 3:
        return FarmerOnboardingValidator.validateStep3(
          status: state.selectedStatus,
          idNumber: state.idNumber,
          uploadedSelfie: state.uploadedSelfie,
          uploadedIdFront: state.uploadedIdFront,
          uploadedIdBack: state.uploadedIdBack,
          bank: state.selectedBank,
          iban: state.iban,
        );
      case 4:
        return FarmerOnboardingValidator.validateStep4(
          isPickupEnabled: state.isPickupEnabled,
          isDeliveryEnabled: state.isDeliveryEnabled,
          deliveryDays: state.deliveryDays,
        );
      case 5:
        return FarmerOnboardingValidator.validateStep5(
          agreeTerms: state.agreeTerms,
          agreeQuality: state.agreeQuality,
        );
      default:
        return null;
    }
  }

  Future<void> _onNext() async {
    HapticFeedback.lightImpact();
    final state = ref.read(farmerOnboardingProvider);
    final currentStep = state.currentStep;
    final notifier = ref.read(farmerOnboardingProvider.notifier);

    final error = _validateStep(currentStep, state);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    if (currentStep < 6) {
      final nextStep = currentStep + 1;
      notifier.setStep(nextStep);

      if (nextStep == 6) {
        final email = notifier.resolveVerificationEmail();
        final sent = await notifier.sendOtp();
        if (!mounted) return;
        if (sent) {
          AppToast.success(
            context,
            'ვერიფიკაციის კოდი გაიგზავნა: $email',
            icon: LucideIcons.mailCheck,
          );
        }
      }
    } else {
      final otpCode = _pinControllers.map((c) => c.text.trim()).join();
      final error = await notifier.verifyOtp(otpCode);
      if (!mounted) return;
      if (error != null) {
        AppToast.error(context, error);
        return;
      }
      _onCompleteOnboarding();
    }
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    final currentStep = ref.read(farmerOnboardingProvider).currentStep;
    if (currentStep > 1) {
      ref.read(farmerOnboardingProvider.notifier).previousStep();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onCompleteOnboarding() {
    ref.read(farmerOnboardingProvider.notifier).completeOnboarding();
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppToast.success(
      context,
      'ფერმერის პროფილი წარმატებით შეიქმნა და ვერიფიცირდა!',
    );
  }

  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 1:
        return Step1FarmInfoWidget(
          farmNameController: _farmNameController,
        );
      case 2:
        return const Step2StatusSelectionWidget();
      case 3:
        return Step3LegalAndBankWidget(
          idNumberController: _idNumberController,
          ibanController: _ibanController,
        );
      case 4:
        return const Step4DeliveryWidget();
      case 5:
        return Step4ReviewAndTermsWidget(
          farmNameController: _farmNameController,
          ibanController: _ibanController,
        );
      case 6:
        return Step5SmsVerificationWidget(
          pinControllers: _pinControllers,
          pinFocusNodes: _pinFocusNodes,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressBar(int currentStep) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(6, (index) {
              final isCompletedOrActive = index < currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 5 ? 5.0 : 0.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isCompletedOrActive
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$currentStep/6',
              key: ValueKey<int>(currentStep),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerOnboardingProvider);
    final currentStep = state.currentStep;

    final String? stepError = _validateStep(currentStep, state);
    final bool canProceed = stepError == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: _onBack,
        ),
        title: _buildProgressBar(currentStep),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(currentStep),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: _buildStepContent(currentStep),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: PrimaryButton(
                text: currentStep == 6 ? 'დადასტურება' : 'შემდეგი',
                height: 52,
                borderRadius: BorderRadius.circular(12),
                backgroundColor: canProceed
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.55),
                onPressed: _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
