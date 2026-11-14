import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/farmer_onboarding_validator.dart';
import '../widgets/farmer_map_widget.dart';

enum LegalStatus {
  physical(
    'ფიზიკური პირი',
    'სასოფლო-სამეურნეო საქმიანობა პირადი ნომრით',
    LucideIcons.user,
  ),
  entrepreneur(
    'ინდ. მეწარმე',
    'რეგისტრირებული ინდივიდუალური მეწარმე',
    LucideIcons.briefcase,
  ),
  company(
    'შპს',
    'იურიდიული პირი და აგრო-კომპანია',
    LucideIcons.building2,
  );

  final String label;
  final String subtitle;
  final IconData icon;
  const LegalStatus(this.label, this.subtitle, this.icon);
}

/// 5-Step Farmer Onboarding & Verification Wizard
/// Strictly adhering to Figma screenshots:
/// - Step 1/5: ფერმის ინფორმაცია & მისამართი (Name, Photo, Region, City, Interactive Map)
/// - Step 2/5: აირჩიე თქვენი სტატუსი (Centered large cards with rich rounded corners)
/// - Step 3/5: იურიდიული დეტალები & საბანკო ანგარიში (ID, Documents Upload, Bank & IBAN)
/// - Step 4/5: დეტალები & წესები და პირობები (Summary review with spacious "შეცვლა" + 2 Checkboxes)
/// - Step 5/5: SMS დადასტურება (5-digit OTP verification & complete onboarding)
class FarmerOnboardingScreen extends ConsumerStatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  ConsumerState<FarmerOnboardingScreen> createState() =>
      _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends ConsumerState<FarmerOnboardingScreen> {
  int _currentStep = 1; // 1 to 5

  // Step 1: Farm Information & Address
  final _farmNameController = TextEditingController();
  bool _hasFarmPhoto = false;
  String _selectedRegion = 'კახეთი';
  String _selectedCity = 'გურჯაანი';
  String _dynamicAddress = 'კახეთი, გურჯაანი';
  LatLng? _selectedLocation;

  final List<String> _regions = [
    'კახეთი',
    'იმერეთი',
    'შიდა ქართლი',
    'ქვემო ქართლი',
    'სამეგრელო',
    'გურია',
    'აჭარა',
    'მცხეთა-მთიანეთი',
  ];

  final Map<String, List<String>> _citiesByRegion = {
    'კახეთი': ['თელავი', 'გურჯაანი', 'ყვარელი', 'საგარეჯო', 'სიღნაღი', 'ახმეტა'],
    'იმერეთი': ['ქუთაისი', 'სამტრედია', 'ზესტაფონი', 'წყალტუბო'],
    'შიდა ქართლი': ['გორი', 'კასპი', 'ხაშური', 'ქარელი'],
    'ქვემო ქართლი': ['რუსთავი', 'მარნეული', 'ბოლნისი'],
    'სამეგრელო': ['ზუგდიდი', 'ფოთი', 'სენაკი'],
    'გურია': ['ოზურგეთი', 'ლანჩხუთი', 'ჩოხატაური'],
    'აჭარა': ['ბათუმი', 'ქობულეთი', 'ხელვაჩაური'],
    'მცხეთა-მთიანეთი': ['მცხეთა', 'დუშეთი', 'ყაზბეგი'],
  };

  // Step 2: Legal Status
  LegalStatus _selectedStatus = LegalStatus.physical;

  // Step 3: Legal Details & Bank
  final _imagePicker = ImagePicker();
  final _idNumberController = TextEditingController();
  bool _uploadedSelfie = false;
  bool _uploadedIdFront = false;
  bool _uploadedIdBack = false;
  String? _farmPhotoName;
  String? _selfieFileName;
  String? _idFrontFileName;
  String? _idBackFileName;
  String _selectedBank = 'TBC';
  final List<String> _banks = ['TBC', 'BOG', 'Liberty Bank', 'BasisBank'];
  final _ibanController = TextEditingController();

  // Step 4: Terms & Conditions Checkboxes
  bool _agreeTerms = false;
  bool _agreeQuality = false;

  // Step 5: SMS OTP Verification
  static const int _pinLength = 5;
  final List<TextEditingController> _pinControllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(_pinLength, (_) => FocusNode());
  int _secondsRemaining = 540;
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
    _farmNameController.dispose();
    _idNumberController.dispose();
    _ibanController.dispose();
    _timer?.cancel();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _detectMyGpsLocation() async {
    HapticFeedback.lightImpact();
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          AppToast.error(
            context,
            'მდებარეობაზე წვდომის ნებართვა უარყოფილია',
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        AppToast.error(
          context,
          'მდებარეობის ნებართვა დაბლოკილია პარამეტრებიდან',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final point = LatLng(pos.latitude, pos.longitude);
      final resolved = GeorgianGeoLookup.resolveInstantAddress(point);
      setState(() {
        _selectedLocation = point;
        _dynamicAddress = resolved;
      });
      AppToast.success(context, 'მისამართი დადგენილია: $resolved');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'GPS მდებარეობის დადგენა ვერ მოხერხდა. შეამოწმეთ ნებართვა.',
      );
    }
  }

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

  Future<void> _pickFarmPhoto() async {
    await _pickPhotoOrDocument(
      label: 'ფერმის ფოტო',
      onSelected: (name) {
        setState(() {
          _hasFarmPhoto = true;
          _farmPhotoName = name;
        });
      },
    );
  }

  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        return FarmerOnboardingValidator.validateStep1(
          farmName: _farmNameController.text,
          hasFarmPhoto: _hasFarmPhoto,
          region: _selectedRegion,
          city: _selectedCity,
        );
      case 3:
        return FarmerOnboardingValidator.validateStep3(
          status: _selectedStatus,
          idNumber: _idNumberController.text,
          uploadedSelfie: _uploadedSelfie,
          uploadedIdFront: _uploadedIdFront,
          uploadedIdBack: _uploadedIdBack,
          bank: _selectedBank,
          iban: _ibanController.text,
        );
      case 4:
        return FarmerOnboardingValidator.validateStep4(
          agreeTerms: _agreeTerms,
          agreeQuality: _agreeQuality,
        );
      case 5:
        final otpCode = _pinControllers.map((c) => c.text.trim()).join();
        return FarmerOnboardingValidator.validateStep5(
          otpCode: otpCode,
          requiredLength: _pinLength,
        );
      default:
        return null;
    }
  }

  String get _verificationEmail {
    final userEmail = ref.read(authStateProvider).userEmail;
    if (userEmail != null && userEmail.isNotEmpty && userEmail != 'example@gmail.com') {
      return userEmail;
    }
    return 'ajariswyali123@gmail.com';
  }

  Future<void> _onNext() async {
    HapticFeedback.lightImpact();
    final validationError = _validateCurrentStep();
    if (validationError != null) {
      AppToast.error(context, validationError);
      return;
    }

    if (_currentStep < 5) {
      final nextStep = _currentStep + 1;
      setState(() => _currentStep = nextStep);
      if (nextStep == 5) {
        final email = _verificationEmail;
        final sent = await ref.read(authStateProvider.notifier).sendEmailOtp(email);
        if (!mounted) return;
        if (sent) {
          AppToast.success(context, 'ვერიფიკაციის კოდი გაიგზავნა: $email');
        }
      }
    } else {
      final otpCode = _pinControllers.map((c) => c.text.trim()).join();
      final error = await ref.read(authStateProvider.notifier).verifyEmailOtp(
            email: _verificationEmail,
            code: otpCode,
          );
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
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onCompleteOnboarding() {
    ref.read(authStateProvider.notifier).completeFarmerOnboarding(
      farmName: _farmNameController.text,
      region: _selectedRegion,
      city: _selectedCity,
      address: _dynamicAddress.isNotEmpty
          ? _dynamicAddress
          : '$_selectedCity, $_selectedRegion',
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
    AppToast.success(
      context,
      'ფერმერის პროფილი წარმატებით შეიქმნა და ვერიფიცირდა!',
    );
  }

  void _openFullScreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FarmerMapWidget(
          isFullScreen: true,
          locationText: _dynamicAddress.isNotEmpty
              ? _dynamicAddress
              : '$_selectedRegion, $_selectedCity',
          initialLocation: _selectedLocation,
          onLocationChanged: (point) {
            setState(() => _selectedLocation = point);
          },
          onAddressResolved: (point, address) {
            setState(() {
              _selectedLocation = point;
              _dynamicAddress = address;
            });
          },
          onToggleFullScreen: () => Navigator.of(context).pop(),
        ),
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
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 28),
          onPressed: _onBack,
        ),
        title: _buildProgressBar(),
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
                  key: ValueKey<int>(_currentStep),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: _buildCurrentStepContent(),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  /// Smooth Segmented Progress Bar (5 distinct pills with modern badge)
  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              final isCompletedOrActive = index < _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 6.0 : 0.0),
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
              '$_currentStep/5',
              key: ValueKey<int>(_currentStep),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: PrimaryButton(
        text: _currentStep == 5 ? 'დადასტურება' : 'შემდეგი',
        height: 52,
        borderRadius: BorderRadius.circular(12),
        onPressed: _onNext,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1FarmInfo();
      case 2:
        return _buildStep2StatusSelection();
      case 3:
        return _buildStep3LegalAndBank();
      case 4:
        return _buildStep4ReviewAndTerms();
      case 5:
        return _buildStep5SmsVerification();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // STEP 1: ფერმის ინფორმაცია & მისამართი
  // ==========================================
  Widget _buildStep1FarmInfo() {
    final availableCities = _citiesByRegion[_selectedRegion] ?? ['თელავი'];
    if (!availableCities.contains(_selectedCity)) {
      _selectedCity = availableCities.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: ფერმის ინფორმაცია
        _buildSectionCard(
          title: 'ფერმის ინფორმაცია',
          icon: LucideIcons.sprout,
          children: [
            _buildFieldLabel('ფერმის/მეურნეობის დასახელება*'),
            const SizedBox(height: 8),
            TextField(
              controller: _farmNameController,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _buildInputDecoration(hint: 'მწვანე ველი'),
            ),
            const SizedBox(height: 18),
            _buildFieldLabel('ატვირთეთ თქვენი ან ფერმის ფოტო *'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFarmPhoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasFarmPhoto ? AppColors.primary : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasFarmPhoto ? LucideIcons.checkCircle2 : LucideIcons.camera,
                      size: 26,
                      color: _hasFarmPhoto ? AppColors.primary : const Color(0xFF334155),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasFarmPhoto
                          ? 'ფოტო ატვირთულია (${_farmPhotoName ?? "farm.jpg"})'
                          : 'ატვირთე (კამერა / გალერეა)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _hasFarmPhoto ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card 2: მისამართი
        _buildSectionCard(
          title: 'მისამართი',
          icon: LucideIcons.mapPin,
          children: [
            _buildFieldLabel('რეგიონი *'),
            const SizedBox(height: 8),
            _buildDropdown(
              title: 'აირჩიეთ რეგიონი',
              value: _selectedRegion,
              items: _regions,
              onChanged: (val) {
                setState(() {
                  _selectedRegion = val;
                  _selectedCity = _citiesByRegion[val]?.first ?? 'თელავი';
                  _dynamicAddress = '$_selectedRegion, $_selectedCity';
                });
              },
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('ქალაქი/რაიონი *'),
            const SizedBox(height: 8),
            _buildDropdown(
              title: 'აირჩიეთ ქალაქი/რაიონი',
              value: _selectedCity,
              items: availableCities,
              onChanged: (val) {
                setState(() {
                  _selectedCity = val;
                  _dynamicAddress = '$_selectedRegion, $_selectedCity';
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _detectMyGpsLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.locateFixed, size: 17),
                label: const Text(
                  'ჩემი მდებარეობის დადგენა (GPS)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FarmerMapWidget(
              locationText: _dynamicAddress.isNotEmpty
                  ? _dynamicAddress
                  : '$_selectedRegion, $_selectedCity',
              initialLocation: _selectedLocation,
              onLocationChanged: (point) {
                setState(() => _selectedLocation = point);
              },
              onAddressResolved: (point, address) {
                setState(() {
                  _selectedLocation = point;
                  _dynamicAddress = address;
                });
              },
              onToggleFullScreen: _openFullScreenMap,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // STEP 2: აირჩიე თქვენი სტატუსი (Item 2 Design Evolution)
  // ==========================================
  Widget _buildStep2StatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sits closely under progress bar
        const SizedBox(height: 0),
        Text(
          'აირჩიე\nთქვენი სტატუსი',
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...LegalStatus.values.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedStatus = status);
              },
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFAFDFB) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: isSelected ? 2.2 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: isSelected ? 12 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Centered large circular icon badge (increased height)
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status.icon,
                              size: 28,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Title below the icon
                          Text(
                            status.label,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),

                          // Explanatory subtitle below title
                          Text(
                            status.subtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isSelected
                                  ? AppColors.primaryDark.withValues(alpha: 0.8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: -5,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // STEP 3: იურიდიული დეტალები & საბანკო ანგარიში
  // ==========================================
  Widget _buildStep3LegalAndBank() {
    final String cardTitle;
    final IconData cardIcon;
    final String idLabel;

    switch (_selectedStatus) {
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
        _buildSectionCard(
          title: cardTitle,
          icon: cardIcon,
          children: [
            _buildFieldLabel(idLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _idNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _buildInputDecoration(hint: '61000000000'),
            ),
            const SizedBox(height: 18),

            // 3 Upload Boxes: სელფი, წინა მხარე, უკანა მხარე (Camera or Gallery)
            Row(
              children: [
                Expanded(
                  child: _buildUploadBox(
                    label: _selfieFileName != null ? 'სელფი ✓' : 'სელფი',
                    icon: LucideIcons.smile,
                    isDone: _uploadedSelfie,
                    onTap: () => _pickPhotoOrDocument(
                      label: 'სელფი პირადობით',
                      preferredCamera: CameraDevice.front,
                      onSelected: (name) {
                        setState(() {
                          _uploadedSelfie = true;
                          _selfieFileName = name;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUploadBox(
                    label: _idFrontFileName != null ? 'წინა მხარე ✓' : 'წინა მხარე',
                    icon: LucideIcons.contact,
                    isDone: _uploadedIdFront,
                    onTap: () => _pickPhotoOrDocument(
                      label: 'პირადობის წინა მხარე',
                      preferredCamera: CameraDevice.rear,
                      onSelected: (name) {
                        setState(() {
                          _uploadedIdFront = true;
                          _idFrontFileName = name;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUploadBox(
                    label: _idBackFileName != null ? 'უკანა მხარე ✓' : 'უკანა მხარე',
                    icon: LucideIcons.creditCard,
                    isDone: _uploadedIdBack,
                    onTap: () => _pickPhotoOrDocument(
                      label: 'პირადობის უკანა მხარე',
                      preferredCamera: CameraDevice.rear,
                      onSelected: (name) {
                        setState(() {
                          _uploadedIdBack = true;
                          _idBackFileName = name;
                        });
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
        _buildSectionCard(
          title: 'საბანკო ანგარიში',
          icon: LucideIcons.creditCard,
          children: [
            _buildFieldLabel('ბენეფიციარი ბანკი *'),
            const SizedBox(height: 8),
            _buildDropdown(
              title: 'აირჩიეთ ბანკი',
              value: _selectedBank,
              items: _banks,
              onChanged: (val) {
                setState(() => _selectedBank = val);
              },
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('ანგარიშის ნომერი (IBAN) *'),
            const SizedBox(height: 8),
            TextField(
              controller: _ibanController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _buildInputDecoration(hint: 'GE**************'),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // STEP 4: დეტალების გადახედვა & წესები
  // ==========================================
  Widget _buildStep4ReviewAndTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'დეტალები',
                    style: AppTypography.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Spacious, perfectly proportioned pill button (Item 3)
                  InkWell(
                    onTap: () => setState(() => _currentStep = 1),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: const Text(
                        'შეცვლა',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReviewRow(
                'სრული სახელი:',
                ref.watch(authStateProvider).userName ?? 'ფერმერი',
              ),
              _buildReviewRow('ფერმის სახელი:', _farmNameController.text.isNotEmpty ? _farmNameController.text : 'ოქროს ქვაფი'),
              _buildReviewRow(
                'მისამართი:',
                _dynamicAddress.isNotEmpty
                    ? _dynamicAddress
                    : '$_selectedRegion, $_selectedCity, 1 რაიონი',
              ),
              _buildReviewRow('ბანკი:', _selectedBank),
              _buildReviewRow('IBAN:', _ibanController.text.length > 7 ? '****${_ibanController.text.substring(_ibanController.text.length - 7)}' : '****7ER9', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms and conditions Card
        _buildSectionCard(
          title: 'წესები და პირობები',
          icon: LucideIcons.building2,
          children: [
            // Checkbox 1 (Custom Modern iOS/AgroKera rounded checkbox)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _agreeTerms = !_agreeTerms);
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomCheckbox(
                    value: _agreeTerms,
                    onChanged: (val) => setState(() => _agreeTerms = val),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'ვეთანხმები agrokera-ს ',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        children: const [
                          TextSpan(
                            text: 'მომსახურების პირობებსა',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' და '),
                          TextSpan(
                            text: 'კონფიდენციალურობის პოლიტიკას',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Checkbox 2 (Custom Modern iOS/AgroKera rounded checkbox)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _agreeQuality = !_agreeQuality);
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomCheckbox(
                    value: _agreeQuality,
                    onChanged: (val) => setState(() => _agreeQuality = val),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ვაცნობიერებ სრულ პასუხისმგებლობას ჩემ მიერ განთავსებული პროდუქციის ხარისხზე, უსაფრთხოებასა და ბუნებრიობაზე.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // STEP 5: SMS დადასტურება
  // ==========================================
  Widget _buildStep5SmsVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            height: 150,
            child: SvgPicture.asset(
              AppAssets.verification,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 28),
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
        Text(
          'კოდი გაიგზავნა $_verificationEmail',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // 5 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_pinLength, (index) {
            return SizedBox(
              width: 54,
              height: 58,
              child: TextField(
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
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
                    _pinFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _pinFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Resend
        Center(
          child: GestureDetector(
            onTap: () async {
              setState(() => _secondsRemaining = 540);
              _startTimer();
              await ref.read(authStateProvider.notifier).sendEmailOtp(_verificationEmail);
              if (!mounted) return;
              AppToast.success(
                context,
                'ახალი კოდი გაიგზავნა $_verificationEmail-ზე.',
              );
            },
            child: RichText(
              text: TextSpan(
                text: 'არ მიგიღიათ კოდი? ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(
                    text: 'ახლიდან გაგზავნა',
                    style: TextStyle(
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
        const SizedBox(height: 20),

        // Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.clock, size: 18, color: Color(0xFF64748B)),
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
        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================
  // SHARED WIDGET HELPERS
  // ==========================================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.titleMedium.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  /// Modern, Elegant Selection BottomSheet (Item 1 Dropdown Fix)
  Widget _buildDropdown({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () => _openSelectionSheet(
        title: title,
        selectedValue: value,
        items: items,
        onSelected: onChanged,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(LucideIcons.chevronDown, size: 20, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  void _openSelectionSheet({
    required String title,
    required String selectedValue,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.65,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Pill drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h1.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.x, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == selectedValue;
                    return InkWell(
                      onTap: () {
                        onSelected(item);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEBF7EF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                            ),
                            if (isSelected)
                              const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckbox({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: value ? AppColors.primary : const Color(0xFFCBD5E1),
          width: 1.8,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: value
          ? const Icon(
              LucideIcons.check,
              size: 15,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildUploadBox({
    required String label,
    required IconData icon,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? AppColors.primary : const Color(0xFFCBD5E1),
            width: isDone ? 1.6 : 1.2,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isDone)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primaryLight
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? LucideIcons.fileCheck2 : icon,
                    size: 17,
                    color: isDone ? AppColors.primary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDone) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'ატვირთულია',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String title, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
          ],
        ],
      ),
    );
  }
}
