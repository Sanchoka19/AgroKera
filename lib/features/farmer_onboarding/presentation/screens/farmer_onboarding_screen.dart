import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import 'package:agrokera/core/widgets/primary_button.dart';
import 'package:agrokera/features/auth/presentation/screens/auth_success_splash_screen.dart';
import '../models/farmer_onboarding_state.dart';
import '../providers/farmer_onboarding_provider.dart';
import '../providers/farmer_onboarding_validator.dart';
import '../widgets/onboarding_steps/step1_farm_info_widget.dart';
import '../widgets/onboarding_steps/step2_status_selection_widget.dart';
import '../widgets/onboarding_steps/step4_delivery_widget.dart';
import '../widgets/onboarding_steps/step4_review_and_terms_widget.dart';

// Re-export LegalStatus so existing references across the app remain intact
export '../models/farmer_onboarding_state.dart' show LegalStatus;

/// 4-Step Farmer Onboarding Wizard
/// Clean, high-conversion flow:
/// - Step 1/4: ფერმის ინფორმაცია & მისამართი (Name, optional cover photo, region, city, map)
/// - Step 2/4: აირჩიე თქვენი სტატუსი (Centered large status cards)
/// - Step 3/4: მიწოდების პირობები & გრაფიკი (Self-Pickup, Scheduled Delivery & Day Toggle Buttons)
/// - Step 4/4: დეტალები & წესები და პირობები (Summary review + agreements)
class FarmerOnboardingScreen extends ConsumerStatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  ConsumerState<FarmerOnboardingScreen> createState() =>
      _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends ConsumerState<FarmerOnboardingScreen> {
  final _farmNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final st = ref.read(farmerOnboardingProvider);
    _farmNameController.text = st.farmName;
  }

  @override
  void dispose() {
    _farmNameController.dispose();
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
        return FarmerOnboardingValidator.validateStep4(
          isPickupEnabled: state.isPickupEnabled,
          isDeliveryEnabled: state.isDeliveryEnabled,
          deliveryDays: state.deliveryDays,
        );
      case 4:
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

    if (currentStep < 4) {
      final nextStep = currentStep + 1;
      notifier.setStep(nextStep);
    } else {
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
    AuthSuccessSplashScreen.navigate(context, message: 'ფერმერის პროფილი შეიქმნა');
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
        return const Step4DeliveryWidget();
      case 4:
        return Step4ReviewAndTermsWidget(
          farmNameController: _farmNameController,
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
            children: List.generate(4, (index) {
              final isCompletedOrActive = index < currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 5.0 : 0.0),
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
              '$currentStep/4',
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
                text: currentStep == 4 ? 'დადასტურება' : 'შემდეგი',
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
