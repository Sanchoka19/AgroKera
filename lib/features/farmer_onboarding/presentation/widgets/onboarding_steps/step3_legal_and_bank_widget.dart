import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/core/theme/app_colors.dart';
import 'package:agrokera/core/widgets/app_toast.dart';
import '../../models/farmer_onboarding_state.dart';
import '../../providers/farmer_onboarding_provider.dart';
import '../onboarding_shared_widgets.dart';

class Step3LegalAndBankWidget extends ConsumerStatefulWidget {
  final TextEditingController idNumberController;
  final TextEditingController ibanController;

  const Step3LegalAndBankWidget({
    super.key,
    required this.idNumberController,
    required this.ibanController,
  });

  @override
  ConsumerState<Step3LegalAndBankWidget> createState() =>
      _Step3LegalAndBankWidgetState();
}

class _Step3LegalAndBankWidgetState
    extends ConsumerState<Step3LegalAndBankWidget> {
  final _imagePicker = ImagePicker();

  Future<void> _captureDocumentWithCamera({
    required String label,
    CameraDevice preferredCamera = CameraDevice.rear,
    required ValueChanged<String> onCaptured,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCamera,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (file != null) {
        onCaptured(file.name);
        AppToast.success(context, '$label წარმატებით გადაღებულია!');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        'კამერაზე წვდომა ვერ მოხერხდა (${e.message ?? "შეამოწმეთ ნებართვა"})',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'კამერის გახსნა ვერ მოხერხდა. გთხოვთ დართოთ კამერის ნებართვა.',
      );
    }
  }

  Future<void> _pickPhotoOrDocument({
    required String label,
    CameraDevice preferredCamera = CameraDevice.rear,
    required ValueChanged<String> onSelected,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                  title: const Text(
                    'კამერით გადაღება',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('მოითხოვს კამერის ნებართვას'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _captureDocumentWithCamera(
                      label: label,
                      preferredCamera: preferredCamera,
                      onCaptured: onSelected,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image, color: AppColors.primary),
                  title: const Text(
                    'გალერეიდან არჩევა',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? file = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (!mounted) return;
                      if (file != null) {
                        onSelected(file.name);
                        AppToast.success(context, '$label წარმატებით აიტვირთა!');
                      }
                    } catch (_) {
                      if (!mounted) return;
                      AppToast.error(context, 'ფოტოს არჩევა ვერ მოხერხდა');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerOnboardingProvider);

    final String cardTitle;
    final IconData cardIcon;
    final String idLabel;

    switch (state.selectedStatus) {
      case LegalStatus.physical:
        cardTitle = 'ფიზიკური პირის დეტალები';
        cardIcon = LucideIcons.user;
        idLabel = 'პირადი ნომერი *';
        break;
      case LegalStatus.entrepreneur:
        cardTitle = 'ინდ. მეწარმის დეტალები';
        cardIcon = LucideIcons.briefcase;
        idLabel = 'საიდენტიფიკაციო ნომერი *';
        break;
      case LegalStatus.company:
        cardTitle = 'შპს დეტალები';
        cardIcon = LucideIcons.building2;
        idLabel = 'საიდენტიფიკაციო ნომერი *';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Legal details & document upload
        OnboardingSectionCard(
          title: cardTitle,
          icon: cardIcon,
          children: [
            OnboardingFieldLabel(idLabel),
            const SizedBox(height: 8),
            TextField(
              controller: widget.idNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: onboardingInputDecoration(hint: '61000000000'),
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setIdNumber(val);
              },
            ),
            const SizedBox(height: 18),

            // 3 Upload Boxes: სელფი, წინა მხარე, უკანა მხარე
            Row(
              children: [
                Expanded(
                  child: OnboardingUploadBox(
                    label: state.selfieFileName != null ? 'სელფი ✓' : 'სელფი',
                    icon: LucideIcons.smile,
                    isDone: state.uploadedSelfie,
                    onTap: () => _pickPhotoOrDocument(
                      label: 'სელფი პირადობით',
                      preferredCamera: CameraDevice.front,
                      onSelected: (name) {
                        ref
                            .read(farmerOnboardingProvider.notifier)
                            .setSelfie(name);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OnboardingUploadBox(
                    label: state.idFrontFileName != null
                        ? 'წინა მხარე ✓'
                        : 'წინა მხარე',
                    icon: LucideIcons.contact,
                    isDone: state.uploadedIdFront,
                    onTap: () => _pickPhotoOrDocument(
                      label: 'პირადობის წინა მხარე',
                      preferredCamera: CameraDevice.rear,
                      onSelected: (name) {
                        ref
                            .read(farmerOnboardingProvider.notifier)
                            .setIdFront(name);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OnboardingUploadBox(
                    label: state.idBackFileName != null
                        ? 'უკანა მხარე ✓'
                        : 'უკანა მხარე',
                    icon: LucideIcons.creditCard,
                    isDone: state.uploadedIdBack,
                    onTap: () => _pickPhotoOrDocument(
                      label: 'პირადობის უკანა მხარე',
                      preferredCamera: CameraDevice.rear,
                      onSelected: (name) {
                        ref
                            .read(farmerOnboardingProvider.notifier)
                            .setIdBack(name);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'გთხოვთ, ატვირთოთ თქვენი პირადობის მოწმობის ორივე მხარე და სელფი, სადაც გიჭირავთ იგივე დოკუმენტი.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark.withValues(alpha: 0.85),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card 2: საბანკო ანგარიში
        OnboardingSectionCard(
          title: 'საბანკო ანგარიში',
          icon: LucideIcons.creditCard,
          children: [
            const OnboardingFieldLabel('ბენეფიციარი ბანკი *'),
            const SizedBox(height: 8),
            OnboardingDropdown(
              title: 'აირჩიეთ ბანკი',
              value: state.selectedBank,
              items: FarmerOnboardingState.banks,
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setBank(val);
              },
            ),
            const SizedBox(height: 16),
            const OnboardingFieldLabel('ანგარიშის ნომერი (IBAN) *'),
            const SizedBox(height: 8),
            TextField(
              controller: widget.ibanController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: onboardingInputDecoration(hint: 'GE**************'),
              onChanged: (val) {
                ref.read(farmerOnboardingProvider.notifier).setIban(val);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
